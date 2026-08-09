# frozen_string_literal: true

module Payments
  class Process
    def initialize(payment:, gateway:)
      @payment = payment
      @gateway = gateway
    end

    def call
      @payment.process!

      result = @gateway.charge(
        amount: @payment.amount,
        currency: @payment.currency
      )

      if result[:success]
        @payment.update!(
          status: "succeeded",
          gateway_transaction_id: result[:transaction_id],
          paid_at: Time.current
        )
      else
        @payment.update!(
          status: "failed",
          gateway_transaction_id: result[:transaction_id],
          failure_code: result[:failure_code],
          failure_message: result[:failure_message]
        )
      end

      @payment
    end
  end
end
