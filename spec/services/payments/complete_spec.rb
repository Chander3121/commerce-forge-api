# frozen_string_literal: true

require "rails_helper"

RSpec.describe Payments::Complete do
  describe "#call" do
    let(:order) { create(:order, status: "pending") }

    let(:payment) do
      create(
        :payment,
        order: order,
        amount: order.total,
        currency: order.currency,
        status: "succeeded",
        gateway: "razorpay"
      )
    end

    subject(:complete_payment) do
      described_class.new(payment: payment).call
    end

    it "confirms the order" do
      expect { complete_payment }
        .to change { order.reload.status }
        .from("pending")
        .to("confirmed")
    end

    it "returns the payment" do
      expect(complete_payment).to eq(payment)
    end

    it "rejects a payment that has not succeeded" do
      payment.update_column(:status, "pending")

      expect { complete_payment }
        .to raise_error(
          ArgumentError,
          "Payment must be succeeded before completing the order"
        )
    end

    it "does not complete a failed payment" do
      payment.update_column(:status, "failed")

      expect { complete_payment }
        .to raise_error(
          ArgumentError,
          "Payment must be succeeded before completing the order"
        )

      expect(order.reload.status).to eq("pending")
    end
  end
end
