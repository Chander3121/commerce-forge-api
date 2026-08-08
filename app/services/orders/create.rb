# frozen_string_literal: true

module Orders
  class Create
    def initialize(user:, items:)
      @user = user
      @items = items
    end

    def call
      Order.transaction do
        order = Order.create!(
          user: @user,
          status: "pending",
          subtotal: 0,
          total: 0,
          currency: "INR"
        )

        @items.each do |item|
          product = item.fetch(:product)
          quantity = item.fetch(:quantity)

          raise ArgumentError, "Quantity must be greater than 0" unless quantity.positive?

          unit_price = product.price
          total_price = unit_price * quantity

          order.order_items.create!(
            product: product,
            quantity: quantity,
            unit_price: unit_price,
            total_price: total_price
          )
        end

        Orders::CalculateTotals.new(order).call
        order.save!

        order
      end
    end
  end
end
