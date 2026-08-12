# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Payments Webhook API", type: :request do
  path "/api/v1/payments/webhook" do
    post "Process Razorpay webhook" do
      tags "Payments Webhook"
      consumes "application/json"
      produces "application/json"

      parameter name: :"X-Razorpay-Signature",
                in: :header,
                type: :string,
                required: true,
                description: "Razorpay webhook signature"

      parameter name: :"X-Razorpay-Event-Id",
                in: :header,
                type: :string,
                required: false,
                description: "Unique Razorpay webhook event ID"

      parameter name: :payload,
                in: :body,
                required: true,
                schema: {
                  type: :object,
                  properties: {
                    event: {
                      type: :string,
                      example: "payment.captured"
                    },
                    payload: {
                      type: :object,
                      properties: {
                        payment: {
                          type: :object,
                          properties: {
                            entity: {
                              type: :object,
                              properties: {
                                id: {
                                  type: :string,
                                  example: "pay_123"
                                },
                                status: {
                                  type: :string,
                                  example: "captured"
                                },
                                error_code: {
                                  type: :string,
                                  nullable: true,
                                  example: "card_declined"
                                },
                                error_description: {
                                  type: :string,
                                  nullable: true,
                                  example: "Card was declined"
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  },
                  required: [ "event", "payload" ]
                }

      response "200", "webhook processed successfully" do
        let(:payload) do
          {
            event: "payment.captured",
            payload: {
              payment: {
                entity: {
                  id: "pay_123",
                  status: "captured"
                }
              }
            }
          }
        end

        let(:"X-Razorpay-Signature") { "test-signature" }
        let(:"X-Razorpay-Event-Id") { "evt_123" }

        before do
          verifier = instance_double(
            Payments::WebhookVerifier,
            valid?: true
          )

          allow(Payments::WebhookVerifier)
            .to receive(:new)
            .and_return(verifier)

          webhook = instance_double(
            Payments::Webhook,
            call: true
          )

          allow(Payments::Webhook)
            .to receive(:new)
            .and_return(webhook)
        end

        run_test!
      end

      response "401", "invalid webhook signature" do
        let(:payload) do
          {
            event: "payment.captured",
            payload: {
              payment: {
                entity: {
                  id: "pay_123",
                  status: "captured"
                }
              }
            }
          }
        end

        let(:"X-Razorpay-Signature") { "invalid" }
        let(:"X-Razorpay-Event-Id") { "evt_123" }

        before do
          verifier = instance_double(
            Payments::WebhookVerifier,
            valid?: false
          )

          allow(Payments::WebhookVerifier)
            .to receive(:new)
            .and_return(verifier)
        end

        run_test!
      end

      response "422", "webhook event ID is required" do
        let(:payload) do
          {
            event: "payment.captured",
            payload: {
              payment: {
                entity: {
                  id: "pay_123",
                  status: "captured"
                }
              }
            }
          }
        end

        let(:"X-Razorpay-Signature") { "test-signature" }

        before do
          verifier = instance_double(
            Payments::WebhookVerifier,
            valid?: true
          )

          allow(Payments::WebhookVerifier)
            .to receive(:new)
            .and_return(verifier)
        end

        run_test!
      end

      response "422", "invalid webhook payload" do
        schema(
          type: :object,
          properties: {
            success: {
              type: :boolean,
              example: false
            },
            message: {
              type: :string,
              example: "Invalid webhook payload."
            },
            errors: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  code: {
                    type: :string,
                    example: "INVALID_WEBHOOK_PAYLOAD"
                  },
                  message: {
                    type: :string,
                    example: "Invalid webhook payload."
                  }
                }
              }
            }
          }
        )
      end
    end
  end
end
