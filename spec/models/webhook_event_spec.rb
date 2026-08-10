# frozen_string_literal: true

require "rails_helper"

RSpec.describe WebhookEvent do
  describe "validations" do
    subject(:webhook_event) do
      described_class.new(
        event_id: "evt_123",
        provider: "razorpay",
        event_type: "payment.captured"
      )
    end

    it "requires an event id" do
      webhook_event.event_id = nil

      expect(webhook_event).not_to be_valid
      expect(webhook_event.errors[:event_id]).to include("can't be blank")
    end

    it "does not allow duplicate event ids for the same provider" do
      create(
        :webhook_event,
        event_id: "evt_123",
        provider: "razorpay"
      )

      expect(webhook_event).not_to be_valid
      expect(webhook_event.errors[:event_id]).to include("has already been taken")
    end
  end
end
