# frozen_string_literal: true

FactoryBot.define do
  factory :order do
    association :user

    status { "pending" }
    subtotal { 1000.00 }
    total { 1000.00 }
    currency { "INR" }
  end
end
