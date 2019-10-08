require 'spec_helper'

module RubyEventStore
  module Mappers
    module Transformation
      RSpec.describe Transformation::SerializedRecord do
        let(:time)            { Time.now.utc }
        let(:serialized_time) { time.iso8601(TIME_PRECISION) }
        let(:uuid)            { SecureRandom.uuid }
        let(:record) {
          RubyEventStore::SerializedRecord.new(
            event_id: uuid,
            data: "---\n:some: value\n",
            metadata: "---\n:some: meta\n",
            event_type: 'TestEvent',
            timestamp: serialized_time
          )
        }
        let(:item) {
          Item.new(
            event_id:   uuid,
            data: "---\n:some: value\n",
            metadata: "---\n:some: meta\n",
            event_type: 'TestEvent',
            timestamp: time
          )
        }

        specify "#dump" do
          expect(SerializedRecord.new.dump(item)).to eq(record)
        end

        specify "#load" do
          expect(SerializedRecord.new.load(record)).to eq(item)
        end
      end
    end
  end
end
