# frozen_string_literal: true

require "rails_helper"

RSpec.describe Orders::Create do
  describe "#call" do
    let(:user) { create(:user) }
    let(:customer) { create(:customer) }
    let(:product) { create(:product, price: 500) }

    it "creates an order" do
      order = described_class.new(
        user: user,
        customer: customer,
        items: [
          {
            product: product,
            quantity: 2
          }
        ]
      ).call

      expect(order).to be_persisted
      expect(order.user).to eq(user)
      expect(order.customer).to eq(customer)
    end

    it "creates order items" do
      order = described_class.new(
        customer: customer,
        user: user,
        items: [ { product: product, quantity: 2 } ]
      ).call

      expect(order.order_items.count).to eq(1)

      item = order.order_items.first

      expect(item.product).to eq(product)
      expect(item.quantity).to eq(2)
      expect(item.unit_price).to eq(500)
      expect(item.total_price).to eq(1000)
    end

    it "snapshots the product price" do
      order = described_class.new(
        customer: customer,
        user: user,
        items: [ { product: product, quantity: 2 } ]
      ).call

      product.update!(price: 800)

      expect(order.order_items.first.unit_price).to eq(500)
      expect(order.order_items.first.total_price).to eq(1000)
    end

    it "calculates the order totals" do
      product_1 = create(:product, price: 500)
      product_2 = create(:product, price: 300)

      order = described_class.new(
        customer: customer,
        user: user,
        items: [
          { product: product_1, quantity: 2 },
          { product: product_2, quantity: 3 }
        ]
      ).call

      expect(order.subtotal).to eq(1900)
      expect(order.total).to eq(1900)
    end

    it "creates the order with pending status" do
      order = described_class.new(
        customer: customer,
        user: user,
        items: [ { product: product, quantity: 1 } ]
      ).call

      expect(order.status).to eq("pending")
    end

    it "rolls back the transaction when an item cannot be created" do
      invalid_product = create(:product, price: 500)

      allow_any_instance_of(OrderItem)
        .to receive(:save!)
        .and_raise(ActiveRecord::RecordInvalid.new(OrderItem.new))

      expect do
        described_class.new(
          customer: customer,
          user: user,
          items: [ { product: invalid_product, quantity: 1 } ]
        ).call
      end.to raise_error(ActiveRecord::RecordInvalid)

      expect(Order.count).to eq(0)
      expect(OrderItem.count).to eq(0)
    end

    it "rejects zero quantity" do
      expect do
        described_class.new(
          customer: customer,
          user: user,
          items: [ { product: product, quantity: 0 } ]
        ).call
      end.to raise_error(
        ArgumentError,
        "Quantity must be greater than 0"
      )

      expect(Order.count).to eq(0)
      expect(OrderItem.count).to eq(0)
    end

    it "rejects negative quantity" do
      expect do
        described_class.new(
          customer: customer,
          user: user,
          items: [ { product: product, quantity: -1 } ]
        ).call
      end.to raise_error(
        ArgumentError,
        "Quantity must be greater than 0"
      )

      expect(Order.count).to eq(0)
      expect(OrderItem.count).to eq(0)
    end

    it "rejects an inactive product" do
      product.update!(status: "inactive")

      expect do
        described_class.new(
          customer: customer,
          user: user,
          items: [
            {
              product: product,
              quantity: 1
            }
          ]
        ).call
      end.to raise_error(
        ArgumentError,
        "Product is not available for ordering"
      )

      expect(Order.count).to eq(0)
    end
  end
end
