# frozen_string_literal: true

FactoryBot.define do
  factory :product do
    category
    sequence(:name) { |n| "Product #{n}" }
    sequence(:slug) { |n| "product-#{n}" }
    description { "A CommerceForge product." }
    price { 999.99 }
    status { "active" }
  end
end
