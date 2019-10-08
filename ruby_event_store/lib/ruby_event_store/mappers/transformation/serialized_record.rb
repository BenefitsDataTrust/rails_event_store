# frozen_string_literal: true

module RubyEventStore
  module Mappers
    module Transformation
      class SerializedRecord
        def dump(item)
          RubyEventStore::SerializedRecord.new(
            event_id:   item.event_id,
            metadata:   item.metadata,
            data:       item.data,
            event_type: item.event_type,
            timestamp:  item.timestamp.iso8601(TIME_PRECISION),
          )
        end

        def load(serialized_record)
          Item.new(
            event_id:   serialized_record.event_id,
            metadata:   serialized_record.metadata,
            data:       serialized_record.data,
            event_type: serialized_record.event_type,
            timestamp:  Time.iso8601(serialized_record.timestamp),
          )
        end
      end
    end
  end
end
