
format do
  view :search_error, cache: :never do
    sr_class = search_with_params.class.to_s

    # don't show card content; not very helpful in this case
    %(#{sr_class} :: #{search_with_params.message})
  end

  def cql_hash
    cql_keyword? ? card.parse_json_cql(keyword) : super
  end

  def keyword
    @keyword ||= search_vars&.dig :keyword
  end

  def search_vars
    root.respond_to?(:search_params) ? root.search_params[:vars] : search_params[:vars]
  end

  def cql_keyword?
    keyword&.match?(/^\{.+\}$/)
  end
end

format :html do
  view :title, cache: :never do
    return super() unless (keyword = search_keyword) &&
                          (title = keyword_search_title(keyword))
    voo.title = title
  end

  def keyword_search_title keyword
    %(Search results for: <span class="search-keyword">#{h keyword}</span>)
  end
end

format :json do
  view :complete, cache: :never do
    term = term_param
    exact = Card.fetch term, new: {}

    {
      search: true,
      term: term,
      add: add_item(exact),
      new: new_item_of_type(exact),
      goto: goto_items(term, exact)
    }
  end

  def add_item exact
    return unless exact.new_card? &&
                  exact.name.valid? &&
                  !exact.virtual? &&
                  exact.ok?(:create)
    [h(exact.name), URI.escape(exact.name)]
  end

  def new_item_of_type exact
    return unless (exact.type_id == CardtypeID) &&
                  Card.new(type_id: exact.id).ok?(:create)
    [exact.name, "new/#{exact.name.url_key}"]
  end

  def goto_items term, exact
    goto_names = complete_or_match_search start_only: Card.config.navbox_match_start_only
    goto_names.unshift exact.name if add_exact_to_goto_names? exact, goto_names
    goto_names.map do |name|
      [name, name.to_name.url_key, h(highlight(name, term, sanitize: false))]
    end
  end

  def add_exact_to_goto_names? exact, goto_names
    exact.known? && !goto_names.find { |n| n.to_name.key == exact.key }
  end

  def term_param
    term = query_params[:keyword]
    if (term =~ /^\+/) && (main = params["main"])
      term = main + term
    end
    term
  end
end
