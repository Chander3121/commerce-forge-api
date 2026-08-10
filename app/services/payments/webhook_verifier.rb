# frozen_string_literal: true

module Payments
  class WebhookVerifier
    def initialize(payload:, signature:, secret:)
      @payload = payload
      @signature = signature
      @secret = secret
    end

    def valid?
      expected_signature = OpenSSL::HMAC.hexdigest(
        "SHA256",
        @secret,
        @payload
      )

      ActiveSupport::SecurityUtils.secure_compare(
        expected_signature,
        @signature
      )
    end
  end
end
