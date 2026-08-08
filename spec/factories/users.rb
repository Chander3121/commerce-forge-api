# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user-#{n}@commerceforge.dev" }
    password { "Password@123" }
    password_confirmation { "Password@123" }
    jti { SecureRandom.uuid }
  end
end
