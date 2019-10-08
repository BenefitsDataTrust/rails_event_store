# frozen_string_literal: true

module RubyEventStore
  module Mappers
    module Transformation
      class DomainEvent
        def dump(domain_event)
          Item.new(
            event_id:   domain_event.event_id,
            metadata:   domain_event.metadata.to_h.reject { |k, _| k.eql?(:timestamp) },
            data:       domain_event.data,
            event_type: domain_event.event_type,
            timestamp:  domain_event.timestamp,
          )
        end

        def load(item)
          Object.const_get(item.event_type).new(
            event_id: item.event_id,
            metadata: item.metadata.merge(timestamp: item.timestamp),
            data:     item.data
          )
        end
      end
    end
  end
end
