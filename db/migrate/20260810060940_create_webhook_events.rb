class CreateWebhookEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :webhook_events do |t|
      t.string :event_id
      t.string :provider
      t.string :event_type

      t.timestamps
    end
  end
end
