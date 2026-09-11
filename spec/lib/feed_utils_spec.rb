require "rails_helper"

RSpec.describe FeedUtils do
  Response = Struct.new(:body)

  describe ".discover_feed_from_url" do
    it "resolves a relative rss alternate link from a schemeless url" do
      response = Response.new(<<~HTML)
        <html>
          <head>
            <link rel="alternate" type="application/rss+xml" title="The Verge" href="/rss/index.xml">
          </head>
        </html>
      HTML

      allow(described_class).to receive(:safe_get)
        .with("https://theverge.com")
        .and_return(response)

      expect(described_class.discover_feed_from_url("theverge.com"))
        .to eq("https://theverge.com/rss/index.xml")
    end
  end
end
