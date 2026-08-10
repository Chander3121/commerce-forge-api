class WebhookEvent < ApplicationRecord
  validates :event_id, :provider, :event_type, presence: true

  validates :event_id,
            uniqueness: { scope: :provider }
end
