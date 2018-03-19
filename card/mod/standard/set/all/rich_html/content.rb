def show_comment_box_in_related?
  false
end

def help_rule_card
  setting = new_card? ? [:add_help, { fallback: :help }] : :help
  help_card = rule_card(*setting)
  help_card if help_card && help_card.ok?(:read)
end

format :html do
  def show view, args
    send "show_#{show_layout? ? :with : :without}_layout", view, args
  end

  def show_layout?
    !Env.ajax? || params[:layout]
  end

  def show_with_layout view, args
    args[:view] = view if view
    @main = false
    @main_opts = args
    render! :layout, layout: params[:layout]
    # FIXME: using title because it's a standard view option.  hack!
  end

  def show_without_layout view, args
    @main = true if params[:is_main] || args[:main]
    view ||= args[:home_view] || :open
    render! view, args
  end

  view :layout, perms: :none, cache: :never do
    layout = process_content get_layout_content(voo.layout),
                             content_opts: { chunk_list: :references }
    output [layout, _render_modal_slot]
  end

  view :content do
    class_up "card-slot", "d0-card-content"
    voo.hide :menu
    wrap { [_render_menu, _render_core] }
  end

  view :content_panel do
    class_up "card-slot", "d0-card-content card"
    voo.hide :menu
    wrap do
      wrap_with :div, class: "card-body" do
        [_render_menu, _render_core]
      end
    end
  end

  view :titled, tags: :comment do
    @content_body = true
    wrap do
      [
        _render_menu,
        _render_header,
        wrap_body { _render_titled_content },
        render_comment_box
      ]
    end
  end

  view :labeled do
    class_up "d0-card-body", "labeled-content"
    @content_body = true
    wrap do
      [
        _render_menu,
        labeled_row
      ]
    end
  end

  def labeled_row
    haml do
      <<-HAML.strip_heredoc
        .row
          .col-4.text-right
            .label
              = _render_title
          .col
            = wrap_body { _render_labeled_content }
      HAML
    end
  end

  view :type_info do
    return unless show_view?(:toolbar, :hide) && card.type_code != :basic
    wrap_with :span, class: "type-info float-right" do
      link_to_card card.type_name, nil, class: "navbar-link"
    end
  end

  view :open, tags: :comment do
    voo.show! :toolbar if toolbar_pinned?
    voo.viz :toggle, (main? ? :hide : :show)
    @content_body = true
    frame do
      [_render_open_content, render_comment_box]
    end
  end

  # view :anchor, perms: :none, tags: :unknown_ok do |args|
  #   %{ <a id="#{card.name.url_key}" name="#{card.name.url_key}"></a> }
  # end

  view :type do |args|
    klasses = ["cardtype", args[:type_class]].compact
    link_to_card card.type_card, nil, class: klasses
  end

  view :closed do
    with_nest_mode :closed do
      voo.show :toggle
      voo.hide! :toolbar
      class_up "d0-card-body", "closed-content"
      @content_body = true
      @toggle_mode = :close
      frame { _render :closed_content }
    end
  end

  view :change do
    voo.show :title_link
    voo.hide :menu
    wrap do
      [_render_title,
       _render_menu,
       _render_last_action]
    end
  end

  def current_set_card
    set_name = params[:current_set]
    if card.known? && card.type_id == Card::CardtypeID
      set_name ||= "#{card.name}+*type"
    end
    set_name ||= "#{card.name}+*self"
    Card.fetch(set_name)
  end

  # subheader = with_name_context(card.name) do
  #   subformat(rcard)._render_title(args)
  # end

  view :related, cache: :never do |args|
    related_card, options = related_card_and_options args
    return unless related_card
    voo.show :toolbar, :menu, :help
    frame do
      voo.hide :header, :toggle
      nest related_card, options
    end
  end

  def related_card_and_options args
    return unless (options = related_options(args))
    related_card = related_card_from_options options
    options[:view] ||= :open
    options[:show] ||= []
    options[:show] << :comment_box if related_card.show_comment_box_in_related?
    [related_card, options]
  end

  def related_options args
    options = (args[:related] || params[:related])
    case options
    when String
      { name: options }
    when Hash
      options.symbolize_keys
    when ActionController::Parameters
      options.to_unsafe_h.symbolize_keys
    end
  end

  def related_card_from_options options
    related_card = options.delete :card
    return related_card if related_card
    related_name = options.delete(:name).to_name.absolute_name card.name
    Card.fetch related_name, new: {}
  end

  view :help, tags: :unknown_ok do
    help_text = voo.help || rule_based_help
    return "" unless help_text.present?
    wrap_with :div, help_text, class: classy("help-text")
  end

  def rule_based_help
    return "" unless (rule_card = card.help_rule_card)
    with_nest_mode :normal do
      process_content _render_raw(structure: rule_card.name),
                      content_opts: { chunk_list: :references }
      # render help card with current card's format
      # so current card's context is used in help card nests
    end
  end

  view :last_action do
    act = card.last_act
    return unless act
    action = act.action_on card.id
    return unless action
    action_verb =
      case action.action_type
      when :create then "added"
      when :delete then "deleted"
      else
        link_to_view :history, "edited", class: "last-edited", rel: "nofollow"
      end

    %(
      <span class="last-update">
        #{action_verb} #{_render_acted_at} ago by
        #{subformat(card.last_actor)._render_link}
      </span>
    )
  end
end
