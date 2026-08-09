# frozen_string_literal: true

require "rails_helper"

RSpec.describe Payments::Create do
  describe "#call" do
    let(:order) { create(:order, subtotal: 1000, total: 1180, currency: "INR") }
    let(:gateway) { "razorpay" }

    subject(:payment) do
      described_class.new(
        order: order,
        gateway: gateway,
        idempotency_key: "payment-123"
      ).call
    end

    it "creates a payment for the order" do
      expect { payment }
        .to change(Payment, :count).by(1)

      expect(payment.order).to eq(order)
    end

    it "uses the order total as the payment amount" do
      expect(payment.amount).to eq(1180)
    end

    it "uses the order currency" do
      expect(payment.currency).to eq("INR")
    end

    it "creates the payment with pending status" do
      expect(payment.status).to eq("pending")
    end

    it "stores the payment gateway" do
      expect(payment.gateway).to eq("razorpay")
    end

    it "does not allow the client to control the payment amount" do
      payment = described_class.new(
        order: order,
        gateway: gateway,
        idempotency_key: "payment-amount-test",
        amount: 1
      ).call

      expect(payment.amount).to eq(1180)
    end

    it "returns the existing payment when the idempotency key was already used" do
      first_payment = described_class.new(
        order: order,
        gateway: gateway,
        idempotency_key: "payment-123"
      ).call

      expect {
        described_class.new(
          order: order,
          gateway: gateway,
          idempotency_key: "payment-123"
        ).call
      }.not_to change(Payment, :count)

      second_payment = described_class.new(
        order: order,
        gateway: gateway,
        idempotency_key: "payment-123"
      ).call

      expect(second_payment).to eq(first_payment)
    end

    it "creates a new payment for a different idempotency key" do
      described_class.new(
        order: order,
        gateway: gateway,
        idempotency_key: "payment-123"
      ).call

      expect {
        described_class.new(
          order: order,
          gateway: gateway,
          idempotency_key: "payment-456"
        ).call
      }.to change(Payment, :count).by(1)
    end

    it "rejects reuse of an idempotency key for a different order" do
      described_class.new(
        order: order,
        gateway: gateway,
        idempotency_key: "payment-123"
      ).call

      another_order = create(
        :order,
        subtotal: 2000,
        total: 2360,
        currency: "INR"
      )

      expect do
        described_class.new(
          order: another_order,
          gateway: gateway,
          idempotency_key: "payment-123"
        ).call
      end.to raise_error(
        ArgumentError,
        "Idempotency key has already been used for another order"
      )
    end
  end
end
