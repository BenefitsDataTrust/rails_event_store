require 'spec_helper'
require 'ruby_event_store/spec/mapper_lint'

module RubyEventStore
  module Mappers
    RSpec.describe NullMapper do
      let(:time)            { Time.now.utc }
      let(:serialized_time) { time.iso8601(TIME_PRECISION) }
      let(:data)            { {some_attribute: 5} }
      let(:metadata)        { {some_meta: 1} }
      let(:event_id)        { SecureRandom.uuid }
      let(:domain_event)    { TimestampEnrichment.with_timestamp(TestEvent.new(data: data, metadata: metadata, event_id: event_id), time) }

      it_behaves_like :mapper, NullMapper.new, TimestampEnrichment.with_timestamp(TestEvent.new)

      specify '#event_to_serialized_record' do
        record = subject.event_to_serialized_record(domain_event)

        expect(record.event_id).to      eq(event_id)
        expect(record.data).to          eq(data)
        expect(record.metadata.to_h).to eq({ some_meta: 1 })
        expect(record.event_type).to    eq("TestEvent")
        expect(record.timestamp).to     eq(serialized_time)
      end

      specify '#serialized_record_to_event' do
        record = subject.event_to_serialized_record(domain_event)
        event  = subject.serialized_record_to_event(record)

        expect(event).to               eq(domain_event)
        expect(event.event_id).to      eq(domain_event.event_id)
        expect(event.data).to          eq(domain_event.data)
        expect(event.metadata.to_h).to eq(domain_event.metadata.to_h)
        expect(event.event_type).to    eq("TestEvent")
        expect(event.timestamp).to     eq(time)
      end
    end
  end
end
