class AddWebhookEventConstraints < ActiveRecord::Migration[8.1]
  def change
    change_column_null :webhook_events, :event_id, false
    change_column_null :webhook_events, :provider, false
    change_column_null :webhook_events, :event_type, false

    add_index :webhook_events,
              [ :provider, :event_id ],
              unique: true
  end
end
