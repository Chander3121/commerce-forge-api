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
        return existing_payment if existing_payment.order_id == @order.id

        raise ArgumentError,
          "Idempotency key has already been used for another order"
      end

      successful_payment = Payment.find_by(
        order_id: @order.id,
        status: "succeeded"
      )

      if successful_payment
        raise ArgumentError, "Order has already been paid."
      end

      Payment.create!(
        order: @order,
        amount: @order.total,
        currency: @order.currency,
        status: "pending",
        gateway: @gateway,
        idempotency_key: @idempotency_key
      )
    rescue ActiveRecord::RecordNotUnique
      recover_from_duplicate_create
    end

    private

    def recover_from_duplicate_create
      existing_payment = Payment.find_by(
        idempotency_key: @idempotency_key
      )

      if existing_payment
        return existing_payment if existing_payment.order_id == @order.id

        raise ArgumentError,
          "Idempotency key has already been used for another order"
      end

      successful_payment = Payment.find_by(
        order_id: @order.id,
        status: "succeeded"
      )

      if successful_payment
        raise ArgumentError, "Order has already been paid."
      end

      raise
    end
  end
end
