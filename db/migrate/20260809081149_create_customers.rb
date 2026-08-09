class CreateCustomers < ActiveRecord::Migration[8.1]
  def change
    create_table :customers, id: :uuid do |t|
      t.string :name
      t.string :email
      t.string :phone

      t.timestamps
    end

    add_index :customers, :email, unique: true
    add_index :customers, :phone
  end
end
