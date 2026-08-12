class AddCategoryToProducts < ActiveRecord::Migration[8.1]
  def change
    add_reference :products, :category, type: :uuid, null: false, foreign_key: true
  end
end
