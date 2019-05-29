
module ClassMethods
  def default_category_id
    @@default_category_id ||=
      Card[:all].fetch(trait: :default, skip_modules: true).category_id
  end
end

def category_card
  return if category_id.nil?
  Card.quick_fetch category_id.to_i
end

def category_code
  Card::Codename[category_id.to_i]
end

def category_name
  category_card.try :name
end

alias_method :category, :category_name

def category_name_or_default
  category_card.try(:name) || Card.quick_fetch(Card.default_category_id).name
end

def category_cardname
  category_card.try :name
end

def category= category_name
  self.category_id = Card.fetch_id category_name
end

def category_known?
  category_id.present?
end

def get_category_id_from_structure
  return unless name && (t = template)
  reset_patterns # still necessary even with new template handling?
  t.category_id
end

event :validate_category_change, :validate, on: :update, changed: :category_id do
  if (c = dup) && c.action == :create && !c.valid?
    errors.add :category, tr(
      :error_cant_change_errors,
      name: name, category_id: category_id,
      error_messages: c.errors.full_messages
    )
  end
end

event :validate_category, :validate, changed: :category_id, on: :save do
  errors.add :category, tr(:error_no_such_category) unless category_name

  if (rt = structure) && rt.assigns_category? && category_id != rt.category_id
    errors.add :category,
               tr(:error_hard_templated, name: name, category_name: rt.category_name)
  end
end
