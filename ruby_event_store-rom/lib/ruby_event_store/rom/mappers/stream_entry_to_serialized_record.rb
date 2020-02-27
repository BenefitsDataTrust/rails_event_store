# frozen_string_literal: true

require 'rom/transformer'

module RubyEventStore
  module ROM
    module Mappers
      class StreamEntryToSerializedRecord < ::ROM::Transformer
        relation :stream_entries
        register_as :stream_entry_to_serialized_record

        map_array do
          unwrap :event, %i[data metadata event_type created_at]
          rename_keys created_at: :timestamp
          map_value :timestamp, ->(timestamp) { timestamp.to_time.utc.iso8601(TIME_PRECISION) }
          accept_keys %i[event_id data metadata event_type timestamp]
          constructor_inject RubyEventStore::SerializedRecord
        end
      end
    end
  end
end
