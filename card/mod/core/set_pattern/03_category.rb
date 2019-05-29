def label name
  %(All "#{name}" cards)
end

def short_label name
  %(all "#{name}s")
end

def prototype_args anchor
  { category: anchor }
end

def pattern_applies? card
  !!card.category_id
end

def anchor_name card
  card.category_name
end

def anchor_id card
  card.category_id
end
