# frozen_string_literal: true

class CreateEventStoreOutbox < ActiveRecord::Migration<%= migration_version %>
  def change
    create_table(:event_store_outbox, force: false) do |t|
      t.string :split_key, null: true
      t.string :format, null: false
      t.binary :payload, null: false
      t.datetime :created_at, null: false
      t.datetime :enqueued_at, null: true
    end
    add_index :event_store_outbox, [:format, :enqueued_at, :split_key], name: "index_event_store_outbox_for_pool"
    add_index :event_store_outbox, [:created_at, :enqueued_at], name: "index_event_store_outbox_for_clear"
  end
end
