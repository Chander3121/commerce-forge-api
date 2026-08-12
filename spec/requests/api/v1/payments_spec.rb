# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Payments", type: :request do
  describe "POST /api/v1/orders/:order_id/payments" do
    let(:user) { create(:user) }

    let(:order) do
      create(
        :order,
        user: user,
        subtotal: 1000,
        total: 1180,
        currency: "INR",
        status: "pending"
      )
    end

    let(:headers) do
      authenticated_headers(user)
    end

    let(:idempotency_key) { "payment-123" }

    subject(:create_payment) do
      post(
        "/api/v1/orders/#{order.id}/payments",
        headers: headers.merge(
          "Idempotency-Key" => idempotency_key
        )
      )
    end

    context "when user is not authenticated" do
      let(:headers) { {} }

      it "returns unauthorized" do
        create_payment

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when user is authenticated" do
      context "when user does not have orders.update permission" do
        let(:user) { create(:user) }

        it "returns forbidden" do
          create_payment

          expect(response).to have_http_status(:forbidden)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(false)
          expect(body["errors"]).to include(
            "code" => "AUTHORIZATION_FAILED",
            "message" => "You are not authorized to perform this action."
          )
        end
      end

      it "does not allow the client to control the payment amount" do
        create_payment

        expect(response).not_to have_http_status(:bad_request)
      end

      context "when user has orders.update permission" do
        before do
          role = create(:role)

          permission = create(
            :permission,
            name: "Update Orders",
            code: "orders.update"
          )

          create(
            :role_permission,
            role: role,
            permission: permission
          )

          create(
            :user_role,
            user: user,
            role: role
          )
        end

        it "creates and processes the payment using the order total" do
          gateway = instance_double(Payments::Gateway)

          allow(Payments::RazorpayGateway).to receive(:new).and_return(gateway)

          allow(gateway).to receive(:charge).with(
            amount: order.total,
            currency: order.currency
          ).and_return(
            success: true,
            transaction_id: "txn_123"
          )

          create_payment

          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(true)
          expect(body["data"]["payment"]["amount"]).to eq(order.total.to_s)
          expect(body["data"]["payment"]["gateway_transaction_id"]).to eq("txn_123")
          expect(body["data"]["payment"]["status"]).to eq("succeeded")
          expect(order.reload.status).to eq("confirmed")
        end

        it "does not create a duplicate payment for the same idempotency key" do
          gateway = instance_double(Payments::Gateway)

          allow(Payments::RazorpayGateway).to receive(:new).and_return(gateway)

          allow(gateway).to receive(:charge).with(
            amount: order.total,
            currency: order.currency
          ).and_return(
            success: true,
            transaction_id: "txn_123"
          )

          create_payment
          first_payment_id = JSON.parse(response.body)["data"]["payment"]["id"]

          create_payment
          second_payment_id = JSON.parse(response.body)["data"]["payment"]["id"]

          expect(second_payment_id).to eq(first_payment_id)
          expect(Payment.where(order: order).count).to eq(1)
        end

        it "returns an error when the payment gateway rejects the payment" do
          gateway = instance_double(Payments::Gateway)

          allow(Payments::RazorpayGateway).to receive(:new).and_return(gateway)

          allow(gateway).to receive(:charge).with(
            amount: order.total,
            currency: order.currency
          ).and_return(
            success: false,
            transaction_id: "txn_456",
            failure_code: "card_declined",
            failure_message: "Card was declined"
          )

          create_payment

          expect(response).to have_http_status(:unprocessable_content)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(false)
          expect(body["errors"]).to include(
            "code" => "card_declined",
            "message" => "Card was declined"
          )

          expect(Payment.last.status).to eq("failed")
          expect(Payment.last.failure_code).to eq("card_declined")
        end

        it "requires an idempotency key" do
          post(
            "/api/v1/orders/#{order.id}/payments",
            headers: authenticated_headers(user)
          )

          expect(response).to have_http_status(:unprocessable_content)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(false)
          expect(body["errors"]).to include(
            "code" => "IDEMPOTENCY_KEY_REQUIRED",
            "message" => "Idempotency-Key header is required."
          )
        end

        it "does not allow another payment for an already succeeded payment" do
          gateway = instance_double(Payments::Gateway)

          allow(Payments::RazorpayGateway).to receive(:new).and_return(gateway)

          allow(gateway).to receive(:charge).with(
            amount: order.total,
            currency: order.currency
          ).and_return(
            success: true,
            transaction_id: "txn_123"
          )

          create_payment

          expect(response).to have_http_status(:ok)
          expect(Payment.where(order: order).count).to eq(1)

          post(
            "/api/v1/orders/#{order.id}/payments",
            headers: authenticated_headers(user).merge(
              "Idempotency-Key" => "payment-456"
            )
          )

          expect(response).to have_http_status(:unprocessable_content)

          expect(Payment.where(order: order).count).to eq(1)
          expect(gateway).to have_received(:charge).once
        end
      end
    end
  end
end
