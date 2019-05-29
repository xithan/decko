class AddCategoryId < ActiveRecord::Migration[5.2]
  def change
    add_column :cards, :category_id, :integer
    add_index :cards, [:category_id], name: "cards_category_id_index"
  end
end
