format :html do
  ###---( TOP_LEVEL (used by menu) NEW / EDIT VIEWS )

  view :new, perms: :create, tags: :unknown_ok do |args|
    frame_and_form :create, args, 'main-success' => 'REDIRECT' do
      [
        _optional_render(:name_formgroup, args),
        _optional_render(:type_formgroup, args),
        _optional_render(:content_formgroup, args),
        _optional_render(:button_formgroup, args)
      ]
    end
  end

  def default_new_args_for_name_field_or_title args
    if !params[:name_prompt] && !card.cardname.blank?
      # name is ready and will show up in title
      hidden[:card][:name] ||= card.name
    else
      # name is not ready; need generic title
      args[:title] ||= if card.type_id == Card.default_type_id
                         'New'
                       else
                         "New #{card.type_name}"
                       end
      # FIXME: - overrides nest args
      unless card.rule_card :autoname
        # prompt for name
        hidden[:name_prompt] = true unless hidden.has_key? :name_prompt
        args[:optional_name_formgroup] ||= :show
      end
    end
    args[:optional_name_formgroup] ||= :hide
  end

  def default_new_args_for_type_field args
    if !params[:type] &&
       !args[:type] &&
       (main? || card.simple? || card.is_template?) &&
       Card.new(type_id: card.type_id).ok?(:create)
      # otherwise current type won't be on menu

      args[:optional_type_formgroup] = :show
    else
      hidden[:card][:type_id] ||= card.type_id
      args[:optional_type_formgroup] = :hide
    end
  end

  def default_new_args_buttons args
    cancel =
      if main?
        { class: 'redirecter', href: Card.path_setting('/*previous') }
      else
        { class: 'slotter', href: path(view: :missing) }
      end

    args[:buttons] ||= %{
      #{submit_button class: 'create-submit-button'}
      #{button_tag 'Cancel',
                   type: 'button',
                   class: "create-cancel-button #{cancel[:class]}",
                   href: cancel[:href]}
    }
  end

  def default_new_args args
    hidden = args[:hidden] ||= {}
    hidden[:success] ||= card.rule(:thanks) || '_self'
    hidden[:card] ||= {}

    args[:optional_help] ||= :show

    default_new_args_for_name_field_or_title args
    default_new_args_for_type_field args
    default_new_args_buttons args
  end

  view :edit, perms: :update, tags: :unknown_ok do |args|
    frame_and_form :update, args.merge(optional_toolbar: :show) do
      [
        _optional_render(:content_formgroup, args),
        _optional_render(:button_formgroup, args)
      ]
    end
  end

  def default_edit_args args
    args[:optional_help] ||= :show
    args[:optional_toolbar] ||= :show

    args[:buttons] ||= %{
      #{submit_button class: 'submit-button'}
      #{button_tag 'Cancel',
                   class: 'cancel-button slotter',
                   href: (args[:cancel_path] || path), type: 'button',
                   'data-slot-selector' => args[:cancel_slot_selector]}
    }
  end

  view :edit_name, perms: :update do |args|
    frame_and_form(
      { action: :update, id: card.id }, args, 'main-success' => 'REDIRECT'
    ) do
      [
        _render_name_formgroup(args),
        _optional_render(:confirm_rename, args),
        _optional_render(:button_formgroup, args)
      ]
    end
  end

  view :confirm_rename do |args|
    referers = args[:referers]
    descendants = card.descendants
    msg = "<h5>Are you sure you want to rename <em>#{card.name}</em>?</h5>"
    if referers.any? || descendants.any?
      msg << rename_info(referers, descendants)
    end
    alert 'warning' do
      msg
    end
  end

  def rename_info referers, descendants
    msg = '<h6>This change will...</h6>'
    msg << '<ul>'
    if descendants.any?
      msg << "<li>automatically alter #{descendants.size} related name(s)."\
             '</li>'
    end
    if referers.any?
      msg << "<li>affect at least #{referers.size} reference(s) to " \
             "\"#{card.name}\".</li>"
    end
    msg << '</ul>'
    if referers.any?
      msg << '<p>You may choose to <em>update or ignore</em> the references.' \
             '</p>'
    end
    msg
  end

  def default_edit_name_args args
    referers = args[:referers] = card.extended_referencers
    args[:hidden] ||= {}
    args[:hidden].reverse_merge!(
      success:  '_self',
      old_name: card.name,
      referers: referers.size,
      card:     { update_referencers: false }
    )
    args[:optional_toolbar] ||= :show
    args[:buttons] =
      %{
        #{submit_button text: 'Rename and Update', disable_with: 'Renaming',
                        class: 'renamer-updater'}
        #{button_tag 'Rename',
                     data: { disable_with: 'Renaming' },
                     class: 'renamer'}
        #{button_tag 'Cancel', class: 'slotter',  type: 'button', href: path}
      }
  end

  view :edit_type, perms: :update do |args|
    frame_and_form :update, args do
      # 'main-success'=>'REDIRECT: _self', # adding this back in would make
      # main cards redirect on cardtype changes
      [
        _render_type_formgroup(args),
        optional_render(:button_formgroup, args)
      ]
    end
  end

  def default_edit_type_args args
    args[:variety] = :edit # YUCK!
    args[:optional_toolbar] ||= :show
    args[:hidden] ||= { success: { view: :edit } }
    args[:buttons] = %{
      #{submit_button}
      #{button_tag 'Cancel', href: path(view: :edit), type: 'button',
                             class: 'slotter'}
    }
  end

  view :edit_rules, tags: :unknown_ok do |args|
    view = args[:rule_view] || :common_rules
    slot_args =
      {
        rule_view: view,
        optional_set_navbar: :show,
        optional_set_label: :hide,
        optional_rule_navbar: :hide
      }
    _render_related args.merge(
      related: { card: current_set_card, view: :open, slot: slot_args }
    )
  end

  def default_edit_rules_args args
    args[:optional_toolbar] ||= :show
  end

  # for backwards compatibility
  view :options, view: :edit_rules, mod: All::RichHtml::Editing::HtmlFormat

  view :edit_structure do |args|
    slot_args =
      {
        cancel_slot_selector: '.card-slot.related-view',
        cancel_path: card.format.path(view: :edit),
        optional_edit_toolbar: :hide,
        hidden: { success: { view: :open, 'slot[subframe]' => true } }
      }
    render_related args.merge(
      related: { card: card.structure, view: :edit, slot: slot_args }
    )
  end

  def default_edit_structure_args args
    args[:optional_toolbar] ||= :show
  end

  view :edit_nests do |args|
    frame args do
      with_inclusion_mode :edit do
        process_relative_tags optional_toolbar: :hide
      end
    end
  end
  def default_edit_nests_args args
    args[:optional_toolbar] ||= :show
  end

  view :edit_nest_rules do |args|
    view = args[:rule_view] || :field_related_rules
    frame args do
      # with_inclusion_mode :edit do
      nested_fields(args).map do |chunk|
        nest Card.fetch("#{chunk.referee_name}+*self"),
             view: :titled, rule_view: view,
             optional_set_label: :hide,
             optional_rule_navbar: :show
      end
    end
  end

  def default_edit_nest_rules_args args
    args[:optional_toolbar] ||= :show
  end
end
