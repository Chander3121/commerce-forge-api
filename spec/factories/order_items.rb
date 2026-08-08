# frozen_string_literal: true

FactoryBot.define do
  factory :order_item do
    association :order
    association :product

    quantity { 2 }
    unit_price { 500.00 }
    total_price { 1000.00 }
  end
end
