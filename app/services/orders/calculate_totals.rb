# frozen_string_literal: true

module Orders
  class CalculateTotals
    def initialize(order)
      @order = order
    end

    def call
      subtotal = @order.order_items.sum do |item|
        item.quantity * item.unit_price
      end

      @order.subtotal = subtotal
      @order.total = subtotal

      @order
    end
  end
end
