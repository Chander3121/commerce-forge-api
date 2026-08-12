# frozen_string_literal: true

require "rails_helper"

RSpec.describe Payments::Webhook do
  describe "#call" do
    let(:order) do
      create(
        :order,
        subtotal: 1000,
        total: 1180,
        currency: "INR",
        status: "pending"
      )
    end

    let!(:payment) do
      create(
        :payment,
        order: order,
        amount: order.total,
        currency: order.currency,
        status: "processing",
        gateway: "razorpay",
        gateway_transaction_id: "pay_123"
      )
    end

    let(:event_id) { "evt_123" }

    let(:payload) do
      {
        "event" => "payment.captured",
        "payload" => {
          "payment" => {
            "entity" => {
              "id" => "pay_123",
              "status" => "captured"
            }
          }
        }
      }
    end

    subject(:process_webhook) do
      described_class.new(
        event_id: event_id,
        payload: payload
      ).call
    end

    it "marks the payment as succeeded" do
      expect {
        process_webhook
      }.to change {
        payment.reload.status
      }.from("processing").to("succeeded")
    end

    it "confirms the order" do
      expect {
        process_webhook
      }.to change {
        order.reload.status
      }.from("pending").to("confirmed")
    end

    it "does not process the same event twice" do
      process_webhook

      expect {
        described_class.new(
          event_id: event_id,
          payload: payload
        ).call
      }.not_to change {
        WebhookEvent.count
      }

      expect(WebhookEvent.where(
        provider: "razorpay",
        event_id: event_id
      ).count).to eq(1)

      expect(payment.reload.status).to eq("succeeded")
      expect(order.reload.status).to eq("confirmed")
    end

    it "does not fail when the payment is already succeeded" do
      payment.update!(
        status: "succeeded",
        paid_at: Time.current
      )

      expect {
        process_webhook
      }.not_to raise_error

      expect(payment.reload.status).to eq("succeeded")
      expect(order.reload.status).to eq("confirmed")
    end

    it "does not downgrade a succeeded payment when a failed webhook arrives" do
      payment.update!(
        status: "succeeded",
        paid_at: Time.current
      )

      payload["event"] = "payment.failed"
      payload["payload"]["payment"]["entity"].merge!(
        "status" => "failed",
        "error_code" => "card_declined",
        "error_description" => "Card was declined"
      )

      expect {
        process_webhook
      }.not_to raise_error

      expect(payment.reload.status).to eq("succeeded")
      expect(payment.failure_code).to be_nil
      expect(payment.failure_message).to be_nil
    end

    it "marks the payment as failed when the payment fails" do
      payload["event"] = "payment.failed"
      payload["payload"]["payment"]["entity"]["status"] = "failed"

      expect {
        process_webhook
      }.to change {
        payment.reload.status
      }.from("processing").to("failed")
    end

    it "stores failure details when the payment fails" do
      payload["event"] = "payment.failed"
      payload["payload"]["payment"]["entity"].merge!(
        "status" => "failed",
        "error_code" => "card_declined",
        "error_description" => "Card was declined"
      )

      process_webhook

      payment.reload

      expect(payment.status).to eq("failed")
      expect(payment.failure_code).to eq("card_declined")
      expect(payment.failure_message).to eq("Card was declined")
    end

    it "ignores unsupported events" do
      payload["event"] = "some.unknown.event"

      expect {
        process_webhook
      }.not_to change {
        payment.reload.status
      }

      expect(payment.reload.status).to eq("processing")
      expect(order.reload.status).to eq("pending")
    end

    it "does not confirm the order when the payment fails" do
      payload["event"] = "payment.failed"
      payload["payload"]["payment"]["entity"].merge!(
        "status" => "failed",
        "error_code" => "card_declined",
        "error_description" => "Card was declined"
      )

      process_webhook

      expect(payment.reload.status).to eq("failed")
      expect(order.reload.status).to eq("pending")
    end

    it "rolls back payment changes if order update fails" do
      allow(Payment).to receive(:find_by!).and_return(payment)

      allow(payment).to receive(:order).and_return(order)

      allow(order).to receive(:update!).and_raise(
        ActiveRecord::RecordInvalid.new(order)
      )

      expect {
        process_webhook
      }.to raise_error(ActiveRecord::RecordInvalid)

      expect(payment.reload.status).to eq("processing")
      expect(order.reload.status).to eq("pending")

      expect(
        WebhookEvent.exists?(
          provider: "razorpay",
          event_id: event_id
        )
      ).to be(false)
    end
  end
end
