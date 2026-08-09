class AddCustomerToOrders < ActiveRecord::Migration[8.1]
  def change
    add_reference :orders, :customer, null: true, foreign_key: true, type: :uuid
  end
end
