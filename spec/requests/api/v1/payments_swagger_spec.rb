# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Payments API", type: :request do
  path "/api/v1/orders/{order_id}/payments" do
    post "Process payment" do
      tags "Payments"
      consumes "application/json"
      produces "application/json"
      security [ bearerAuth: [] ]

      parameter name: :order_id,
                in: :path,
                type: :string,
                format: :uuid,
                required: true,
                description: "Order ID"

      parameter name: :"Idempotency-Key",
                in: :header,
                type: :string,
                required: false,
                description: "Unique key used to safely retry payment requests"

      response "200", "payment processed successfully" do
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

        let(:order_id) { order.id }
        let(:"Idempotency-Key") { "payment-123" }

        let(:gateway) { instance_double(Payments::Gateway) }

        let(:Authorization) { sign_in(user) }

        before do
          permission = create(
            :permission,
            name: "Update Orders",
            code: "orders.update"
          )

          role = create(:role)

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

          allow(Payments::RazorpayGateway)
            .to receive(:new)
            .and_return(gateway)

          allow(gateway).to receive(:charge).with(
            amount: order.total,
            currency: order.currency
          ).and_return(
            success: true,
            transaction_id: "txn_123"
          )
        end

        schema(
          type: :object,
          properties: {
            success: {
              type: :boolean
            },
            message: {
              type: :string
            },
            data: {
              type: :object,
              properties: {
                payment: {
                  type: :object,
                  properties: {
                    id: {
                      type: :integer
                    },
                    order_id: {
                      type: :string,
                      format: :uuid
                    },
                    amount: {
                      type: :string
                    },
                    currency: {
                      type: :string
                    },
                    status: {
                      type: :string
                    },
                    gateway: {
                      type: :string
                    },
                    gateway_transaction_id: {
                      type: :string
                    },
                    paid_at: {
                      type: :string,
                      format: :"date-time",
                      nullable: true
                    }
                  }
                }
              }
            },
            errors: {
              type: :array
            }
          }
        )

        run_test! do |response|
          expect(response).to have_http_status(:ok)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(true)
          expect(body["message"]).to eq(
            "Payment processed successfully."
          )

          payment = body["data"]["payment"]

          expect(payment["amount"]).to eq(order.total.to_s)
          expect(payment["currency"]).to eq(order.currency)
          expect(payment["status"]).to eq("succeeded")
          expect(payment["gateway_transaction_id"]).to eq("txn_123")

          expect(body["errors"]).to eq([])
        end
      end

      response "401", "authentication failed" do
        let(:order) { create(:order) }
        let(:order_id) { order.id }
        let(:idempotency_key) { "payment-123" }
        let(:Authorization) { nil }

        run_test!
      end

      response "403", "authorization failed" do
        let(:user) { create(:user) }
        let(:order) { create(:order, user: user) }
        let(:order_id) { order.id }
        let(:idempotency_key) { "payment-123" }
        let(:Authorization) { sign_in(user) }

        run_test!
      end

      response "422", "idempotency key is required" do
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

        let(:order_id) { order.id }
        let(:Authorization) { sign_in(user) }

        before do
          permission = create(
            :permission,
            name: "Update Orders",
            code: "orders.update"
          )

          role = create(:role)

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

        run_test! do |response|
          expect(response).to have_http_status(:unprocessable_content)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(false)
          expect(body["errors"]).to include(
            "code" => "IDEMPOTENCY_KEY_REQUIRED",
            "message" => "Idempotency-Key header is required."
          )
        end
      end

      response "422", "payment gateway rejected the payment" do
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

        let(:order_id) { order.id }
        let(:"Idempotency-Key") { "payment-456" }
        let(:Authorization) { sign_in(user) }

        let(:gateway) { instance_double(Payments::Gateway) }

        before do
          permission = create(
            :permission,
            name: "Update Orders",
            code: "orders.update"
          )

          role = create(:role)

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

          allow(Payments::RazorpayGateway)
            .to receive(:new)
            .and_return(gateway)

          allow(gateway).to receive(:charge).with(
            amount: order.total,
            currency: order.currency
          ).and_return(
            success: false,
            transaction_id: "txn_456",
            failure_code: "card_declined",
            failure_message: "Card was declined"
          )
        end

        run_test! do |response|
          expect(response).to have_http_status(:unprocessable_content)

          body = JSON.parse(response.body)

          expect(body["success"]).to be(false)
          expect(body["message"]).to eq("Card was declined")

          expect(body["errors"]).to include(
            "code" => "card_declined",
            "message" => "Card was declined"
          )
        end
      end
    end
  end
end
