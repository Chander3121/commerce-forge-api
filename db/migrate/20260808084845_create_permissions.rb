class CreatePermissions < ActiveRecord::Migration[8.1]
  def change
    create_table :permissions, id: :uuid do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.text :description

      t.timestamps
    end

    add_index :permissions, :code, unique: true
  end
end
