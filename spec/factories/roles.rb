# frozen_string_literal: true

FactoryBot.define do
  factory :role do
    sequence(:name) { |n| "Role #{n}" }
    sequence(:slug) { |n| "role-#{n}" }
    description { "Test role." }
    system { false }
  end
end
