# frozen_string_literal: true

require "rails_helper"

RSpec.describe Payments::WebhookVerifier do
  describe "#valid?" do
    let(:payload) { '{"event":"payment.captured"}' }
    let(:secret) { "webhook-secret" }

    subject(:verifier) do
      described_class.new(
        payload: payload,
        signature: signature,
        secret: secret
      )
    end

    context "when the signature is valid" do
      let(:signature) do
        OpenSSL::HMAC.hexdigest(
          "SHA256",
          secret,
          payload
        )
      end

      it "returns true" do
        expect(verifier.valid?).to be(true)
      end
    end

    context "when the signature is invalid" do
      let(:signature) { "invalid" }

      it "returns false" do
        expect(verifier.valid?).to be(false)
      end
    end
  end
end
