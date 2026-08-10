# frozen_string_literal: true

module Payments
  class Webhook
    def initialize(event_id:, payload:)
      @event_id = event_id
      @payload = payload
    end

    def call
      ActiveRecord::Base.transaction do
        WebhookEvent.create!(
          event_id: @event_id,
          provider: "razorpay",
          event_type: @payload["event"]
        )

        payment = Payment.find_by!(
          gateway_transaction_id: payment_transaction_id
        )

        case @payload["event"]
        when "payment.captured"
          payment.update!(
            status: "succeeded"
          )

          payment.order.update!(
            status: "confirmed"
          )

        when "payment.failed"
          payment.update!(
            status: "failed",
            failure_code: failure_code,
            failure_message: failure_message
          )
        end

        payment
      end
    rescue ActiveRecord::RecordInvalid => e
      raise unless e.record.is_a?(WebhookEvent)

      Payment.find_by!(
        gateway_transaction_id: payment_transaction_id
      )
    end

    private

    def payment_transaction_id
      @payload.dig(
        "payload",
        "payment",
        "entity",
        "id"
      )
    end

    def failure_code
      @payload.dig(
        "payload",
        "payment",
        "entity",
        "error_code"
      )
    end

    def failure_message
      @payload.dig(
        "payload",
        "payment",
        "entity",
        "error_description"
      )
    end
  end
end
