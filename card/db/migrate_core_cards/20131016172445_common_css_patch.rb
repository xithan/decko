# -*- encoding : utf-8 -*-

class CommonCssPatch < Card::Migration::Core
  def up
    dir = File.join data_path, "1.12_stylesheets"
    card = Card["style: common"]
    card.update! content: File.read("#{dir}/common.scss") if card&.pristine?
  end
end
