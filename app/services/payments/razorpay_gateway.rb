# frozen_string_literal: true

module Payments
  class RazorpayGateway < Gateway
    def initialize(client: nil)
      @client = client || Payments::RazorpayClient.new(
        payment_client: Razorpay::Payment
      )
    end

    def charge(amount:, currency:)
      @client.charge(
        amount: amount,
        currency: currency
      )
    end
  end
end
