# frozen_string_literal: true

FactoryBot.define do
  factory :permission do
    sequence(:name) { |n| "Permission #{n}" }
    sequence(:code) { |n| "test.permission.#{n}" }
    description { "Test permission." }
  end
end
