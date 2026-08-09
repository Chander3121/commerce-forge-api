# frozen_string_literal: true

module Payments
  class RazorpayClient
    def initialize(payment_client:)
      @payment_client = payment_client
    end

    def charge(amount:, currency:)
      response = @payment_client.create_json_payment(
        amount: (amount * 100).to_i,
        currency: currency
      )

      {
        success: true,
        transaction_id: response[:id]
      }
    rescue Razorpay::BadRequestError,
           Razorpay::GatewayError,
           Razorpay::ServerError => e
      {
        success: false,
        transaction_id: nil,
        failure_code: e.code,
        failure_message: e.status
      }
    end
  end
end
