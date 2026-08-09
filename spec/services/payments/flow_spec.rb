# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Payment flow" do
  describe "successful payment" do
    let(:order) do
      create(
        :order,
        status: "pending",
        subtotal: 1000,
        total: 1180,
        currency: "INR"
      )
    end

    let(:payment) do
      create(
        :payment,
        order: order,
        amount: order.total,
        currency: order.currency,
        status: "pending",
        gateway: "razorpay",
        idempotency_key: SecureRandom.uuid
      )
    end

    let(:gateway) { instance_double(Payments::Gateway) }

    it "processes the payment and confirms the order" do
      allow(gateway).to receive(:charge).and_return(
        success: true,
        transaction_id: "txn_123"
      )

      Payments::Process.new(
        payment: payment,
        gateway: gateway
      ).call

      Payments::Complete.new(
        payment: payment
      ).call

      expect(payment.reload.status).to eq("succeeded")
      expect(payment.gateway_transaction_id).to eq("txn_123")
      expect(payment.paid_at).not_to be_nil
      expect(order.reload.status).to eq("confirmed")
    end

    it "marks the payment as failed and does not confirm the order" do
      allow(gateway).to receive(:charge).and_return(
        success: false,
        transaction_id: "txn_failed_123",
        failure_code: "card_declined",
        failure_message: "Card was declined"
      )

      Payments::Process.new(
        payment: payment,
        gateway: gateway
      ).call

      expect(payment.reload.status).to eq("failed")
      expect(payment.gateway_transaction_id).to eq("txn_failed_123")
      expect(payment.failure_code).to eq("card_declined")
      expect(payment.failure_message).to eq("Card was declined")
      expect(payment.paid_at).to be_nil
      expect(order.reload.status).to eq("pending")
    end
  end
end
