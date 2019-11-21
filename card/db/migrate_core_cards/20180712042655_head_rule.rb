# -*- encoding : utf-8 -*-

class HeadRule < Card::Migration::Core
  def up
    update_card! :head, type_id: Card::SettingID
    ensure_card %i[all head],
                type_id: Card::HTMLID,
                content: "{{*head|core}}"
    ensure_card %i[head right help],
                content: "head tag content"
    ensure_card %i[head right default], type_id: Card::HtmlID
  end
end
