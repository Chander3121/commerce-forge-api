# frozen_string_literal: true

class CreateOrderItems < ActiveRecord::Migration[8.1]
  def change
    create_table :order_items, id: :uuid do |t|
      t.references :order, null: false, type: :uuid, foreign_key: true
      t.references :product, null: false, type: :uuid, foreign_key: true

      t.integer :quantity, null: false
      t.decimal :unit_price, null: false, precision: 12, scale: 2
      t.decimal :total_price, null: false, precision: 12, scale: 2

      t.timestamps
    end

    add_index :order_items, [ :order_id, :product_id ], unique: true
  end
end
