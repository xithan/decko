include_set Abstract::Pointer

abstract_basket :item_codenames

# simplify api
# Self::MyCodePointerSet.add_item :my_item_codename
# instead of
# Self::MyCodePointerSet.add_to_basket :item_codenames, :my_item_codename
module ClassMethods
  def add_item codename
    valid_codename codename do
      add_to_basket :item_codenames, codename
    end
  end

  def unshift_item codename
    valid_codename codename do
      unshift_basket :item_codenames, codename
    end
  end

  def valid_codename codename
    if Card::Codename.exist? codename
      yield
    else
      Rails.logger.info "unknown codename '#{codename}' added to code pointer"
    end
  end
end

def content
  item_codenames.map do |codename|
    Card.fetch_name codename
  end.compact.to_pointer_content
end
