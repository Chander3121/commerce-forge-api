# frozen_string_literal: true

require "rails_helper"

RSpec.describe Payments::Process do
  describe "#call" do
    let(:order) do
      create(
        :order,
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
        gateway: "razorpay"
      )
    end

    let(:gateway) { instance_double(Payments::Gateway) }

    subject(:process_payment) do
      described_class.new(
        payment: payment,
        gateway: gateway
      ).call
    end

    it "moves the payment to processing" do
      allow(gateway).to receive(:charge).and_return(
        success: true,
        transaction_id: "txn_123"
      )

      expect { process_payment }
        .to change { payment.reload.status }
        .from("pending")
        .to("succeeded")
    end

    it "stores the gateway transaction id" do
      allow(gateway).to receive(:charge).and_return(
        success: true,
        transaction_id: "txn_123"
      )

      process_payment

      expect(payment.reload.gateway_transaction_id).to eq("txn_123")
    end

    it "sets paid_at after successful payment" do
      allow(gateway).to receive(:charge).and_return(
        success: true,
        transaction_id: "txn_123"
      )

      process_payment

      expect(payment.reload.paid_at).not_to be_nil
    end

    it "marks the payment as failed when the gateway rejects it" do
      allow(gateway).to receive(:charge).and_return(
        success: false,
        transaction_id: "txn_456",
        failure_code: "card_declined",
        failure_message: "Card was declined"
      )

      expect { process_payment }
        .to change { payment.reload.status }
        .from("pending")
        .to("failed")
    end

    it "stores gateway failure details" do
      allow(gateway).to receive(:charge).and_return(
        success: false,
        transaction_id: "txn_456",
        failure_code: "card_declined",
        failure_message: "Card was declined"
      )

      process_payment

      payment.reload

      expect(payment.gateway_transaction_id).to eq("txn_456")
      expect(payment.failure_code).to eq("card_declined")
      expect(payment.failure_message).to eq("Card was declined")
    end

    context "with RazorpayGateway" do
      it "processes a payment through the Razorpay gateway" do
        razorpay_client = instance_double(Payments::RazorpayClient)

        allow(Payments::RazorpayClient).to receive(:new)
          .with(payment_client: Razorpay::Payment)
          .and_return(razorpay_client)

        allow(razorpay_client).to receive(:charge).with(
          amount: payment.amount,
          currency: payment.currency
        ).and_return(
          success: true,
          transaction_id: "pay_123"
        )

        gateway = Payments::RazorpayGateway.new

        result = described_class.new(
          payment: payment,
          gateway: gateway
        ).call

        expect(result.reload.status).to eq("succeeded")
        expect(result.gateway_transaction_id).to eq("pay_123")
      end
    end
  end
end
