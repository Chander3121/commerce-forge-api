class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :order, null: false, foreign_key: true, type: :uuid
      t.decimal :amount
      t.string :currency
      t.string :status
      t.string :gateway
      t.string :gateway_transaction_id
      t.string :failure_code
      t.text :failure_message
      t.datetime :paid_at

      t.timestamps
    end
  end
end
