# frozen_string_literal: true

module Payments
  class Gateway
    def charge(amount:, currency:)
      raise NotImplementedError, "Gateway#charge must be implemented"
    end
  end
end
