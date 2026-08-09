# frozen_string_literal: true

FactoryBot.define do
  factory :payment do
    association :order

    amount { 1000.00 }
    currency { "INR" }
    status { "pending" }
    gateway { "razorpay" }
    idempotency_key { SecureRandom.uuid }
    gateway_transaction_id { nil }
    failure_code { nil }
    failure_message { nil }
    paid_at { nil }
  end
end
