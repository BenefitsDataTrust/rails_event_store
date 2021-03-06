require "spec_helper"

module RubyEventStore
  RSpec.describe Browser do
    specify do
      routing = Browser::Routing.new("http://example.com:9393", nil)

      url = routing.paginated_events_from_stream_url(id: "all")

      expect(url).to eq("http://example.com:9393/streams/all/relationships/events")
    end

    specify do
      routing = Browser::Routing.new("http://example.com:9393", "")

      url = routing.paginated_events_from_stream_url(id: "all", position: "forward")

      expect(url).to eq("http://example.com:9393/streams/all/relationships/events/forward")
    end

    specify "escaping stream name" do
      routing = Browser::Routing.new("http://example.com:9393", "")

      url = routing.paginated_events_from_stream_url(id: "foo/bar.xml")

      expect(url).to eq("http://example.com:9393/streams/foo%2Fbar.xml/relationships/events")
    end
  end
end
