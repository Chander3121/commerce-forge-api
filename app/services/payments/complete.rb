# frozen_string_literal: true

module Payments
  class Complete
    def initialize(payment:)
      @payment = payment
    end

    def call
      unless @payment.status == "succeeded"
        raise ArgumentError,
          "Payment must be succeeded before completing the order"
      end

      @payment.order.confirm!

      @payment
    end
  end
end
