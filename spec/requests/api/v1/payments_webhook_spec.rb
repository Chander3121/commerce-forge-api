# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Payments Webhook", type: :request do
  describe "POST /api/v1/payments/webhook" do
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

    let(:webhook_secret) { "webhook-secret" }

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
      }.to_json
    end

    it "rejects a webhook with an invalid signature" do
      post(
        "/api/v1/payments/webhook",
        params: payload,
        headers: {
          "CONTENT_TYPE" => "application/json",
          "X-Razorpay-Signature" => "invalid"
        }
      )

      expect(response).to have_http_status(:unauthorized)
    end

    it "accepts a webhook with a valid signature" do
      signature = OpenSSL::HMAC.hexdigest(
        "SHA256",
        webhook_secret,
        payload
      )

      post(
        "/api/v1/payments/webhook",
        params: payload,
        headers: {
          "CONTENT_TYPE" => "application/json",
          "X-Razorpay-Signature" => signature,
          "X-Razorpay-Event-Id" => event_id
        }
      )

      expect(response).to have_http_status(:ok)
    end

    it "processes a valid payment captured webhook" do
      signature = OpenSSL::HMAC.hexdigest(
        "SHA256",
        webhook_secret,
        payload
      )

      post(
        "/api/v1/payments/webhook",
        params: payload,
        headers: {
          "CONTENT_TYPE" => "application/json",
          "X-Razorpay-Signature" => signature,
          "X-Razorpay-Event-Id" => event_id
        }
      )

      expect(response).to have_http_status(:ok)

      expect(payment.reload.status).to eq("succeeded")
      expect(order.reload.status).to eq("confirmed")

      expect(
        WebhookEvent.exists?(
          provider: "razorpay",
          event_id: event_id
        )
      ).to be(true)
    end

    it "rejects a webhook without an event id" do
      signature = OpenSSL::HMAC.hexdigest(
        "SHA256",
        webhook_secret,
        payload
      )

      post(
        "/api/v1/payments/webhook",
        params: payload,
        headers: {
          "CONTENT_TYPE" => "application/json",
          "X-Razorpay-Signature" => signature
        }
      )

      expect(response).to have_http_status(:unprocessable_content)

      body = JSON.parse(response.body)

      expect(body["success"]).to be(false)
      expect(body["errors"]).to include(
        "code" => "WEBHOOK_EVENT_ID_REQUIRED",
        "message" => "Webhook event id is required."
      )
    end

    it "rejects malformed JSON payload" do
      malformed_payload = '{"event":"payment.captured"'

      signature = OpenSSL::HMAC.hexdigest(
        "SHA256",
        webhook_secret,
        malformed_payload
      )

      post(
        "/api/v1/payments/webhook",
        params: malformed_payload,
        headers: {
          "CONTENT_TYPE" => "application/json",
          "X-Razorpay-Signature" => signature,
          "X-Razorpay-Event-Id" => event_id
        }
      )

      expect(response).to have_http_status(:unprocessable_content)

      body = JSON.parse(response.body)

      expect(body["success"]).to be(false)
      expect(body["errors"]).to include(
        "code" => "INVALID_WEBHOOK_PAYLOAD",
        "message" => "Invalid webhook payload."
      )
    end

    it "does not process the same webhook event twice" do
      signature = OpenSSL::HMAC.hexdigest(
        "SHA256",
        webhook_secret,
        payload
      )

      headers = {
        "CONTENT_TYPE" => "application/json",
        "X-Razorpay-Signature" => signature,
        "X-Razorpay-Event-Id" => event_id
      }

      post(
        "/api/v1/payments/webhook",
        params: payload,
        headers: headers
      )

      expect(response).to have_http_status(:ok)

      expect {
        post(
          "/api/v1/payments/webhook",
          params: payload,
          headers: headers
        )
      }.not_to change(WebhookEvent, :count)

      expect(response).to have_http_status(:ok)

      expect(WebhookEvent.where(
        provider: "razorpay",
        event_id: event_id
      ).count).to eq(1)

      expect(payment.reload.status).to eq("succeeded")
      expect(order.reload.status).to eq("confirmed")
    end

    it "processes a payment failed webhook" do
      failed_payload = {
        "event" => "payment.failed",
        "payload" => {
          "payment" => {
            "entity" => {
              "id" => "pay_123",
              "status" => "failed",
              "error_code" => "card_declined",
              "error_description" => "Card was declined"
            }
          }
        }
      }.to_json

      signature = OpenSSL::HMAC.hexdigest(
        "SHA256",
        webhook_secret,
        failed_payload
      )

      post(
        "/api/v1/payments/webhook",
        params: failed_payload,
        headers: {
          "CONTENT_TYPE" => "application/json",
          "X-Razorpay-Signature" => signature,
          "X-Razorpay-Event-Id" => "evt_failed_123"
        }
      )

      expect(response).to have_http_status(:ok)

      payment.reload
      order.reload

      expect(payment.status).to eq("failed")
      expect(payment.failure_code).to eq("card_declined")
      expect(payment.failure_message).to eq("Card was declined")
      expect(order.status).to eq("pending")
    end
  end
end
