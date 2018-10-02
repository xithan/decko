format :html do
  def follow_section
    return unless show_follow?
    wrap_with :div, class: "mb-3" do
      [follow_button_group, followers_bridge_link, follow_overview_button]
    end
  end

  def follow_button_group
    wrap_with :div, class: "btn-group btn-group-sm" do
      [follow_button, follow_advanced]
    end
  end

  def follow_overview_button
    link_to_card [Auth.current, :follow], "all followed cards",
                 bridge_link_opts(class: "btn btn-sm btn-secondary")
  end

  def follow_advanced
    link_to_card card.follow_rule_card(Auth.current.name), icon_tag("more_horiz"),
                 bridge_link_opts(class:"btn btn-sm btn-primary",
                                  path: { view: :overlay_rule })
  end

  def followers_bridge_link
    cnt = card.followers_count
    link_to_card card.name.field(:followers), "#{cnt} follower#{'s' unless cnt == 1}",
                 bridge_link_opts(class: "btn btn-sm ml-2 btn-secondary slotter", remote: true)
  end
end