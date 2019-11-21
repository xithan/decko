# -*- encoding : utf-8 -*-

RSpec.describe Card::Auth do
  before do
    described_class.current_id = Card::AnonymousID
    @joeuserid = Card["Joe User"].id
  end

  it "authenticates user" do
    authenticated = described_class.authenticate "joe@user.com", "joe_pass"
    expect(authenticated.left_id).to eq(@joeuserid)
  end

  it "authenticates user despite whitespace" do
    authenticated = described_class.authenticate " joe@user.com ", " joe_pass "
    expect(authenticated.left_id).to eq(@joeuserid)
  end

  it "authenticates user with weird email capitalization" do
    authenticated = described_class.authenticate "JOE@user.com", "joe_pass"
    expect(authenticated.left_id).to eq(@joeuserid)
  end

  it "sets current directly from email" do
    described_class.current = "joe@user.com"
    expect(described_class.current_id).to eq(@joeuserid)
  end

  it "sets current directly from id when mark is id" do
    described_class.current = @joeuserid
    expect(described_class.current_id).to eq(@joeuserid)
  end

  it "sets current directly from id when mark is id" do
    described_class.current = @joeuserid
    expect(described_class.current_id).to eq(@joeuserid)
  end

  context "with api key" do
    before do
      @joeadmin = Card["Joe Admin"]
      @api_key = "abcd"
      described_class.as_bot do
        @joeadmin.account.api_key_card.update! content: @api_key
      end
    end

    it "sets current from token" do
      described_class.set_current_from_api_key @api_key
      expect(described_class.current_id).to eq(@joeadmin.id)
    end
  end
end
