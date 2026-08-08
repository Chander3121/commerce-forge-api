# frozen_string_literal: true

class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products, id: :uuid do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.decimal :price, precision: 12, scale: 2, null: false
      t.string :status, null: false, default: "active"

      t.timestamps
    end

    add_index :products, :slug, unique: true
    add_index :products, :status
  end
end
