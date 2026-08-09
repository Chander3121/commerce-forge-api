# frozen_string_literal: true

require "rails_helper"

RSpec.describe Payments::RazorpayGateway do
  describe "#charge" do
    let(:client) { instance_double("RazorpayClient") }

    subject(:gateway) do
      described_class.new(client: client)
    end

    it "charges the requested amount and currency" do
      expect(client).to receive(:charge).with(
        amount: 1180,
        currency: "INR"
      ).and_return(
        success: true,
        transaction_id: "rzp_txn_123"
      )

      result = gateway.charge(
        amount: 1180,
        currency: "INR"
      )

      expect(result).to eq(
        success: true,
        transaction_id: "rzp_txn_123"
      )
    end

    it "returns a normalized failure response" do
      expect(client).to receive(:charge).with(
        amount: 1180,
        currency: "INR"
      ).and_return(
        success: false,
        transaction_id: "rzp_txn_456",
        failure_code: "card_declined",
        failure_message: "Card was declined"
      )

      result = gateway.charge(
        amount: 1180,
        currency: "INR"
      )

      expect(result).to eq(
        success: false,
        transaction_id: "rzp_txn_456",
        failure_code: "card_declined",
        failure_message: "Card was declined"
      )
    end

    it "uses the Razorpay client by default" do
      expect(Payments::RazorpayClient).to receive(:new).with(
        payment_client: Razorpay::Payment
      ).and_return(client)

      expect(client).to receive(:charge).with(
        amount: 1180,
        currency: "INR"
      )

      described_class.new.charge(
        amount: 1180,
        currency: "INR"
      )
    end
  end
end
