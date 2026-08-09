# frozen_string_literal: true

module Payments
  class Create
    def initialize(order:, gateway:, idempotency_key:, amount: nil)
      @order = order
      @gateway = gateway
      @idempotency_key = idempotency_key
      @amount = amount
    end

    def call
      existing_payment = Payment.find_by(
        idempotency_key: @idempotency_key
      )

      if existing_payment
        if existing_payment.order_id != @order.id
          raise ArgumentError,
            "Idempotency key has already been used for another order"
        end

        return existing_payment
      end

      Payment.create!(
        order: @order,
        amount: @order.total,
        currency: @order.currency,
        status: "pending",
        gateway: @gateway,
        idempotency_key: @idempotency_key
      )
    end
  end
end
