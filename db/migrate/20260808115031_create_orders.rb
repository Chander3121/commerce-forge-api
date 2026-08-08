# frozen_string_literal: true

class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true

      t.string :status, null: false, default: "pending"

      t.decimal :subtotal, null: false, precision: 12, scale: 2
      t.decimal :total, null: false, precision: 12, scale: 2

      t.string :currency, null: false, default: "INR"

      t.timestamps
    end

    add_index :orders, :status
  end
end
