# frozen_string_literal: true

require 'active_record'

module RailsEventStoreActiveRecord
  class Event < ::ActiveRecord::Base
    self.primary_key = :id
    self.table_name = 'event_store_events'
    has_many :event_in_streams
  end

  class EventInStream < ::ActiveRecord::Base
    self.primary_key = :id
    self.table_name = 'event_store_events_in_streams'
    belongs_to :event
  end
end
