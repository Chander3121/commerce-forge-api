class CreateRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :roles, id: :uuid do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.boolean :system, null: false, default: false

      t.timestamps
    end

    add_index :roles, :slug, unique: true
  end
end
