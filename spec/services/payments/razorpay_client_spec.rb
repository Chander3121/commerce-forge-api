# frozen_string_literal: true

require "rails_helper"

RSpec.describe Payments::RazorpayClient do
  describe "#charge" do
    let(:client) { class_double(Razorpay::Payment) }

    subject(:razorpay_client) do
      described_class.new(payment_client: client)
    end

    it "creates a Razorpay payment with amount in paise" do
      expect(client).to receive(:create_json_payment).with(
        amount: 118_000,
        currency: "INR"
      ).and_return(
        id: "pay_123"
      )

      result = razorpay_client.charge(
        amount: 1180,
        currency: "INR"
      )

      expect(result).to eq(
        success: true,
        transaction_id: "pay_123"
      )
    end

    it "returns a normalized failure response when Razorpay rejects the payment" do
      error = Razorpay::BadRequestError.new(
        "card_declined",
        "Card was declined"
      )

      expect(client).to receive(:create_json_payment).with(
        amount: 118_000,
        currency: "INR"
      ).and_raise(error)

      result = razorpay_client.charge(
        amount: 1180,
        currency: "INR"
      )

      expect(result).to eq(
        success: false,
        transaction_id: nil,
        failure_code: error.code,
        failure_message: error.status
      )
    end

    it "returns a normalized failure response when Razorpay has a gateway error" do
      error = Razorpay::GatewayError.new(
        "gateway_error",
        "Payment gateway failed"
      )

      expect(client).to receive(:create_json_payment).with(
        amount: 118_000,
        currency: "INR"
      ).and_raise(error)

      result = razorpay_client.charge(
        amount: 1180,
        currency: "INR"
      )

      expect(result).to eq(
        success: false,
        transaction_id: nil,
        failure_code: error.code,
        failure_message: error.status
      )
    end

    it "returns a normalized failure response when Razorpay has a server error" do
      error = Razorpay::ServerError.new(
        "server_error",
        "Razorpay server failed"
      )

      expect(client).to receive(:create_json_payment).with(
        amount: 118_000,
        currency: "INR"
      ).and_raise(error)

      result = razorpay_client.charge(
        amount: 1180,
        currency: "INR"
      )

      expect(result).to eq(
        success: false,
        transaction_id: nil,
        failure_code: error.code,
        failure_message: error.status
      )
    end
  end
end
