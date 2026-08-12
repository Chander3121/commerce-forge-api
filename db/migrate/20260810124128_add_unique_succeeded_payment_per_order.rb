class AddUniqueSucceededPaymentPerOrder < ActiveRecord::Migration[8.1]
  def change
    add_index :payments,
              :order_id,
              unique: true,
              where: "status = 'succeeded'",
              name: "index_payments_on_order_id_succeeded"
  end
end
