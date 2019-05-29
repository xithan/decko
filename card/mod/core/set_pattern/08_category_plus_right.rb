# Patterned field names on a specific type

@@options = {
  junction_only: true,
  assigns_type: true,
  anchor_parts_count: 2
}

def label name
  name = name.to_name
  %(All "+#{name.tag}" cards on "#{name.left}" cards)
end

def short_label name
  name = name.to_name
  %(all "+#{name.tag}" on "#{name.left}s")
end

def prototype_args anchor
  {
    name: "+#{anchor.tag}",
    supercard: Card.new(name: "*dummy", category: anchor.trunk_name)
  }
end

def anchor_name card
  category_name = card.left(new: {})&.category_name || Card.default_category_id.cardname
  "#{category_name}+#{card.name.tag}"
end
