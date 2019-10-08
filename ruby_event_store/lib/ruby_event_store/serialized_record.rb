# frozen_string_literal: true

module RubyEventStore
  class SerializedRecord
    StringsRequired = Class.new(StandardError)
    def initialize(event_id:, data:, metadata:, event_type:, timestamp:)
      raise StringsRequired unless [event_id, event_type].all? { |v| v.instance_of?(String) }
      @event_id   = event_id
      @data       = data
      @metadata   = metadata
      @event_type = event_type
      @timestamp  = timestamp
      freeze
    end

    attr_reader :event_id, :data, :metadata, :event_type, :timestamp

    BIG_VALUE = 0b110011100100000010010010110011101011110101010101001100111110011
    def hash
      [
        self.class,
        event_id,
        data,
        metadata,
        event_type,
        timestamp,
      ].hash ^ BIG_VALUE
    end

    def ==(other)
      other.instance_of?(self.class) &&
        other.event_id.eql?(event_id) &&
        other.data.eql?(data) &&
        other.metadata.eql?(metadata) &&
        other.event_type.eql?(event_type) &&
        other.timestamp.eql?(timestamp)
    end

    def to_h
      {
        event_id: event_id,
        data: data,
        metadata: metadata,
        event_type: event_type,
        timestamp: timestamp,
      }
    end

    alias_method :eql?, :==
  end
end
