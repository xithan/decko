ACTS_PER_PAGE = 50

view :title do
  voo.title = "Recent Changes"
  super()
end

format :html do
  view :core do
    voo.hide :history_legend unless voo.main
    bs_layout container: true, fluid: true do
      html _render_history_legend with_drafts: false
      row 12 do
        html _render_recent_acts
      end
      row 12 do
        col act_paging
      end
    end
  end

  view :recent_acts, cache: :never do
    acts = Act.all_viewable.order(id: :desc)
              .page(page_from_params).per(ACTS_PER_PAGE)
    act_accordion acts do |act, act_seq|
      act.card.format(:html).render_act act: act, act_seq: act_seq, act_context: :absolute
    end
  end

  def act_paging
    acts = Act.all_viewable.order(id: :desc).page(page_from_params).per(ACTS_PER_PAGE)
    wrap_with :span, class: "slotter" do
      paginate acts, remote: true, theme: "twitter-bootstrap-4"
    end
  end
end

format :rss do
  view :feed_item_description do
    render_blank
  end
end
