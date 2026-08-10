FactoryBot.define do
  factory :webhook_event do
    event_id { "MyString" }
    provider { "MyString" }
    event_type { "MyString" }
  end
end
