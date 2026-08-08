class CreateRolePermissions < ActiveRecord::Migration[8.1]
  def change
    create_table :role_permissions, id: :uuid do |t|
      t.references :role, null: false, type: :uuid, foreign_key: true
      t.references :permission, null: false, type: :uuid, foreign_key: true

      t.timestamps
    end

    add_index :role_permissions, [ :role_id, :permission_id ], unique: true
  end
end
