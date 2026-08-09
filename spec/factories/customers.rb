# frozen_string_literal: true

FactoryBot.define do
  factory :customer do
    name { "John Doe" }
    sequence(:email) { |n| "customer#{n}@commerceforge.dev" }
    phone { "9876543210" }
  end
end
