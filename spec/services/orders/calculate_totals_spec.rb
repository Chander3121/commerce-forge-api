# frozen_string_literal: true

require "rails_helper"

RSpec.describe Orders::CalculateTotals do
  describe "#call" do
    it "calculates subtotal and total from order items" do
      order = create(:order)

      create(
        :order_item,
        order: order,
        quantity: 2,
        unit_price: 500,
        total_price: 1000
      )

      create(
        :order_item,
        order: order,
        quantity: 3,
        unit_price: 300,
        total_price: 900
      )

      described_class.new(order).call

      expect(order.subtotal).to eq(1900)
      expect(order.total).to eq(1900)
    end

    it "does not depend on the current product price" do
      product = create(:product, price: 999)
      order = create(:order)

      create(
        :order_item,
        order: order,
        product: product,
        quantity: 2,
        unit_price: 500,
        total_price: 1000
      )

      product.update!(price: 1500)

      described_class.new(order).call

      expect(order.subtotal).to eq(1000)
      expect(order.total).to eq(1000)
    end

    it "returns the order" do
      order = create(:order)

      result = described_class.new(order).call

      expect(result).to eq(order)
    end
  end
end
