module ClassMethods
  def retrieve_from_cache cache_key, local_only=false
    return unless cache

    local_only ? cache.soft.read(cache_key) : cache.read(cache_key)
  end

  def retrieve_from_cache_by_id id, local_only=false
    name = retrieve_from_cache "~#{id}", local_only
    retrieve_from_cache name, local_only if name
  end

  def retrieve_from_cache_by_key key, local_only=false
    retrieve_from_cache key, local_only
  end

  def write_to_cache card, local_only=false
    if local_only
      write_to_soft_cache card
    elsif cache
      cache.write card.key, card
      cache.write "~#{card.id}", card.key if card.id.to_i.nonzero?
    end
  end

  def write_to_soft_cache card
    return unless cache

    cache.soft.write card.key, card
    cache.soft.write "~#{card.id}", card.key if card.id.to_i.nonzero?
  end

  def expire name
    key = name.to_name.key
    return unless (card = Card.cache.read key)

    card.expire
  end

  def new_for_cache card, name, opts
    return if name.is_a? Integer
    return if name.blank? && !opts[:new]
    return if card && (card.type_known? || skip_type_lookup?(opts))

    new name: name,
        skip_modules: true,
        skip_type_lookup: skip_type_lookup?(opts)
  end
end

def expire_pieces
  name.piece_names.each do |piece|
    Card.expire piece
  end
end

def expire cache_type=nil
  return unless (cache_class = cache_class_from_type cache_type)

  expire_views
  expire_names cache_class
  expire_id cache_class
end

def cache_class_from_type cache_type
  cache_type ? Card.cache.send(cache_type) : Card.cache
end

def register_view_cache_key cache_key
  view_cache_keys cache_key
  hard_write_view_cache_keys
end

def view_cache_keys new_key=nil
  @view_cache_keys ||= []
  @view_cache_keys << new_key if new_key
  append_missing_view_cache_keys
  @view_cache_keys.uniq!
  @view_cache_keys
end

def append_missing_view_cache_keys
  return unless Card.cache.hard

  @view_cache_keys +=
    (Card.cache.hard.read_attribute(key, :view_cache_keys) || [])
end

def hard_write_view_cache_keys
  # puts "WRITE VIEW CACHE KEYS (#{name}): #{view_cache_keys}"
  return unless Card.cache.hard

  Card.cache.hard.write_attribute key, :view_cache_keys, view_cache_keys
end

def expire_views
  # puts "EXPIRE VIEW CACHE (#{name}): #{view_cache_keys}"
  return unless view_cache_keys.present?

  Array.wrap(view_cache_keys).each do |view_cache_key|
    Card::View.cache.delete view_cache_key
  end
  @view_cache_keys = nil
end

def expire_names cache
  [name, name_before_act].each do |name_version|
    expire_name name_version, cache
  end
end

def expire_name name_version, cache
  return unless name_version.present?

  key_version = name_version.to_name.key
  return unless key_version.present?

  cache.delete key_version
end

def expire_id cache
  return unless id.present?

  cache.delete "~#{id}"
end
