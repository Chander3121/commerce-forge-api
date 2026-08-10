# frozen_string_literal: true

module Api
  module V1
    class PaymentsWebhookController < ApplicationController
      def create
        payload = request.raw_post
        signature = request.headers["X-Razorpay-Signature"]
        event_id = request.headers["X-Razorpay-Event-Id"]

        verifier = Payments::WebhookVerifier.new(
          payload: payload,
          signature: signature,
          secret: Rails.application.credentials.dig(:razorpay, :webhook_secret)
        )

        return head :unauthorized unless verifier.valid?

        if event_id.blank?
          return render_error(
            message: "Webhook event id is required.",
            errors: [
              {
                code: "WEBHOOK_EVENT_ID_REQUIRED",
                message: "Webhook event id is required."
              }
            ],
            status: :unprocessable_content
          )
        end

        begin
          parsed_payload = JSON.parse(payload)
        rescue JSON::ParserError
          return render_error(
            message: "Invalid webhook payload.",
            errors: [
              {
                code: "INVALID_WEBHOOK_PAYLOAD",
                message: "Invalid webhook payload."
              }
            ],
            status: :unprocessable_content
          )
        end

        Payments::Webhook.new(
          event_id: event_id,
          payload: parsed_payload
        ).call

        head :ok
      end
    end
  end
end
