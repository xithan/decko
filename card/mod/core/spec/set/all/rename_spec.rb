 # -*- encoding : utf-8 -*-

RSpec.describe Card::Set::All::Rename do
  include CardExpectations

  def name_invariant_attributes card
    descendant_ids = []
    card.each_descendant { |d| descendant_ids << d.id }
    {
      content: card.db_content,
      # updater_id:  card.updater_id,
      # revisions:   card.actions.count,
      referers: card.referers.map(&:name).sort,
      referees: card.referees.map(&:name).sort,
      descendants: descendant_ids.sort
    }
  end

  def assert_rename card, new_name
    card = card_to_rename card
    attrs_before = name_invariant_attributes(card)
    actions_count_before = card.actions.count
    #old_name = card.name

    update! card.name, name: new_name, update_referers: true

    expect(card.actions.count).to eq(actions_count_before + 1)
    # expect(Card.cache.read old_name).to eq(nil)
    expect(name_invariant_attributes(card)).to eq(attrs_before)
    expect(Card[new_name]).to eq(card)
  end

  def card_to_rename card
    return card unless card.is_a? String

    Card[card].refresh || raise("Couldn't find card named #{card}")
  end

  it "renames simple card to its own child" do
    assert_rename "F", "F+M"
  end

  it "disallows renaming simple to compound when simple is used as tag" do
    expect { Card["A"].update! name: "A+M" }.to raise_error(/illegal name change/)
  end

  it "renames plus card to its own child" do
    assert_rename "A+B", "A+B+T"
  end

  it "clears cache for old name" do
    assert_rename "Menu", "manure"
    expect(Card["Menu"]).to be_nil
  end

  it "wipes old references by default" do
    update "Menu", name: "manure"
    expect(Card["manure"].references_in.size).to eq(0)
  end

  it "picks up new references" do
    expect(Card["Z"].references_in.size).to eq(2)
    assert_rename "Z", "Mister X"
    expect(Card["Mister X"].references_in.size).to eq(3)
  end

  it "handles name variants" do
    assert_rename "B", "b"
  end

  it "handles plus cards renamed to simple" do
    assert_rename "A+B", "K"
  end

  it "handles flipped parts" do
    assert_rename "A+B", "B+A"
  end

  it "fails if card exists" do
    expect { update "T", name: "A+B" }.to raise_error(/Name must be unique/)
  end

  it "fails if used as tag" do
    expect { update "B", name: "A+D" }.to raise_error(/Name must be unique/)
  end

  it "updates descendants" do
    old_names = %w[One+Two One+Two+Three Four+One Four+One+Five]
    new_names = %w[Uno+Two Uno+Two+Three Four+Uno Four+Uno+Five]
    card_list = old_names.map {|name| Card[name]}

    expect(card_list.map(&:name)).to eq old_names
    update "One", name: "Uno"
    expect(card_list.map(&:id).map(&:cardname)).to eq new_names
  end

  it "fails if name is invalid" do
    expect { update "T", name: "" }
      .to raise_error(/Name can't be blank/)
  end

  example "simple to simple" do
    assert_rename "A", "Alephant"
  end

  example "simple to junction with create" do
    assert_rename "T", "C+J"
  end

  example "reset key" do
    c = Card["basicname"]
    update "basicname", name: "banana card"
    expect(c.key).to eq("banana_card")
    expect(Card["Banana Card"]).not_to be_nil
  end

  it "does not fail when updating inaccessible referer" do
    Card.create! name: "Joe Card", content: "Whattup"
    Card::Auth.as "joe_admin" do
      Card.create! name: "Admin Card", content: "[[Joe Card]]"
    end

    c = Card["Joe Card"]
    c.update! name: "Card of Joe", update_referers: true
    assert_equal "[[Card of Joe]]", Card["Admin Card"].content
  end

  it "test_rename_should_update_structured_referer" do
    Card::Auth.as_bot do
      c = Card.create! name: "Pit"
      Card.create! name: "Orange", type: "Fruit", content: "[[Pit]]"
      Card.create! name: "Fruit+*type+*structure", content: "this [[Pit]]"

      assert_equal "this [[Pit]]", Card["Orange"].content
      c.update! name: "Seed", update_referers: true
      assert_equal "this [[Seed]]", Card["Orange"].content
    end
  end

  it "handles plus cards that have children" do
    assert_rename Card["a+b"], "e+f"
  end

  context "self references" do
    example "renaming card with self link should nothang" do
      pre_content = Card["self_aware"].content
      update "self aware", name: "buttah", update_referers: true
      expect_card("Buttah").to have_content(pre_content)
    end

    it "renames card without updating references" do
      pre_content = Card["self_aware"].content
      update "self aware", name: "Newt", update_referers: false
      expect_card("Newt").to have_content(pre_content)
    end
  end

  context "references" do
    it "updates nests" do
      update "Blue", name: "Red", update_referers: true
      expect_card("blue includer 1").to have_content("{{Red}}")
      expect_card("blue includer 2").to have_content("{{Red|closed;other:stuff}}")
    end

    it "updates nests when renaming to plus" do
      update "Blue", name: "blue includer 1+color", update_referers: true
      expect_card("blue includer 1").to have_content("{{blue includer 1+color}}")
    end

    it "reference updates on case variants" do
      update "Blue", name: "Red", update_referers: true
      expect_card("blue linker 1").to have_content("[[Red]]")
      expect_card("blue linker 2").to have_content("[[Red]]")
    end

    it "handles link to and nest of same card" do
      update "blue linker 1", content: "[[Blue]] is {{Blue|name}}"
      update "Blue", name: "Red", update_referers: true
      expect_card("blue linker 1").to have_content("[[Red]] is {{Red|name}}")
    end

    example "reference updates plus to simple" do
      assert_rename Card["A+B"], "schmuck"
      expect_card("X").to have_content("[[A]] [[schmuck]] [[T]]")
    end

    it "substitutes name part" do
      c1 = Card["A+B"]
      assert_rename Card["B"], "buck"
      expect(Card.find(c1.id).name).to eq "A+buck"
    end
  end
end
