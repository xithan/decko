format :html do
  # Does two main things:
  # (1) gives CSS classes for styling and
  # (2) adds card data for javascript - including the "card-slot" class,
  #     which in principle is not supposed to be in styles
  def wrap slot=true, &block
    method_wrap :wrap_with, slot, &block
  end

  def haml_wrap slot=true, &block
    method_wrap :haml_tag, slot, &block
  end

  def method_wrap method, slot, &block
    @slot_view = @current_view
    debug_slot do
      attribs = { id: card.name.url_key,
                  class: wrap_classes(slot),
                  data:  wrap_data }
      send method, :div, attribs, &block
    end
  end

  def wrap_data slot=true
    with_slot_data slot do
      { "card-id": card.id, "card-name": h(card.name) }
    end
  end

  def with_slot_data slot
    hash = yield
    # rails helper convert slot hash to json
    # but haml joins nested keys with a dash
    hash[:slot] = slot_options_json if slot
    hash
  end

  def slot_options_json
    html_escape_except_quotes JSON(slot_options)
  end

  def slot_options
    options = voo ? voo.slot_options : {}
    name_context_slot_option options
    options
  end

  def name_context_slot_option opts
    return unless initial_context_names.present?
    opts[:name_context] = initial_context_names.map(&:key) * ","
  end

  def debug_slot
    debug_slot? ? debug_slot_wrap { yield } : yield
  end

  def debug_slot?
    params[:debug] == "slot" && !tagged(@current_view, :no_wrap_comments)
  end

  def debug_slot_wrap
    pre = "<!--\n\n#{'  ' * depth}"
    post = " SLOT: #{h card.name}\n\n-->"
    [pre, "BEGIN", post, yield, pre, "END", post].join
  end

  def wrap_classes slot
    list = slot ? ["card-slot"] : []
    list += ["#{@current_view}-view", card.safe_set_keys]
    list << "STRUCTURE-#{voo.structure.to_name.key}" if voo&.structure
    classy list
  end

  def wrap_body
    css_classes = ["d0-card-body"]
    css_classes += ["d0-card-content", card.safe_set_keys] if @content_body
    wrap_with :div, class: classy(*css_classes) do
      yield
    end
  end

  def panel
    wrap_with :div, class: classy("d0-card-frame") do
      yield
    end
  end

  def related_frame
    voo.show :menu
    wrap do
      [
        _render_menu,
        _render_subheader,
        frame_help,
        panel { wrap_body { yield } }
      ]
    end
  end

  def frame &block
    method = show_related_frame? ? :related_frame : :standard_frame
    send method, &block
  end

  def show_related_frame?
    parent && parent.voo.ok_view == :related
  end

  def standard_frame slot=true
    voo.hide :horizontal_menu, :help
    wrap slot do
        panel do
          [
            _render_menu,
            _render_header,
            frame_help,
            _render(:flash),
            wrap_body { yield }
          ]
        end
    end
  end

  def frame_help
    # TODO: address these args
    with_class_up "help-text", "alert alert-info" do
      _render :help
    end
  end

  def frame_and_form action, form_opts={}
    form_opts ||= {}
    frame do
      card_form action, form_opts do
        output yield
      end
    end
  end

  # alert_types: 'success', 'info', 'warning', 'danger'
  def alert alert_type, dismissable=false, disappear=false, args={}
    classes = ["alert", "alert-#{alert_type}"]
    classes << "alert-dismissible " if dismissable
    classes << "_disappear" if disappear
    args.merge! role: "alert"
    add_class args, classy(classes)
    wrap_with :div, args do
      [(alert_close_button if dismissable), output(yield)]
    end
  end

  def alert_close_button
    wrap_with :button, type: "button", "data-dismiss" => "alert",
                       class: "close", "aria-label" => "Close" do
      wrap_with :span, "&times;", "aria-hidden" => true
    end
  end

  def wrap_main
    return yield if Env.ajax? || params[:layout] == "none"
    wrap_with :div, yield, id: "main"
  end

  def wrap_with tag, content_or_args={}, html_args={}
    content = block_given? ? yield : content_or_args
    tag_args = block_given? ? content_or_args : html_args
    content_tag(tag, tag_args) { output(content).to_s.html_safe }
  end

  def wrap_each_with tag, content_or_args={}, args={}
    content = block_given? ? yield(args) : content_or_args
    args    = block_given? ? content_or_args : args
    content.compact.map do |item|
      wrap_with(tag, args) { item }
    end.join "\n"
  end
end
