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

    it "does not process an already succeeded payment" do
      payment.update_column(:status, "succeeded")

      expect(gateway).not_to receive(:charge)

      expect {
        process_payment
      }.to raise_error(
        ArgumentError,
        "Invalid payment status transition"
      )

      expect(payment.reload.status).to eq("succeeded")
    end

    it "does not mark the payment as succeeded before the gateway succeeds" do
      allow(gateway).to receive(:charge).and_return(
        success: false,
        transaction_id: "txn_failed",
        failure_code: "card_declined",
        failure_message: "Card was declined"
      )

      process_payment

      expect(payment.reload.status).to eq("failed")
      expect(payment.paid_at).to be_nil
    end

    it "does not charge an already processing payment" do
      payment.update_column(:status, "processing")

      expect(gateway).not_to receive(:charge)

      expect {
        process_payment
      }.to raise_error(
        ArgumentError,
        "Invalid payment status transition"
      )
    end

    it "keeps the payment processing when the gateway raises an exception" do
      allow(gateway).to receive(:charge)
        .and_raise(StandardError, "Gateway timeout")

      expect {
        process_payment
      }.to raise_error(StandardError, "Gateway timeout")

      expect(payment.reload.status).to eq("processing")
      expect(payment.reload.paid_at).to be_nil
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
