require "rails_helper"

RSpec.describe FeedUtils do
  Response = Struct.new(:body)

  describe ".get_item_author" do
    def parsed_item(xml)
      RSS::Parser.parse(xml, false).items.first
    end

    it "returns the author from an RSS 2.0 item" do
      item = parsed_item(<<~XML)
        <rss version="2.0">
          <channel><title>t</title><link>https://x.com</link><description>d</description>
            <item><title>a</title><author>jane@example.com (Jane Doe)</author></item>
          </channel>
        </rss>
      XML

      expect(described_class.get_item_author(item)).to eq("jane@example.com (Jane Doe)")
    end

    it "returns the dc:creator when author is absent" do
      item = parsed_item(<<~XML)
        <rss version="2.0" xmlns:dc="http://purl.org/dc/elements/1.1/">
          <channel><title>t</title><link>https://x.com</link><description>d</description>
            <item><title>a</title><dc:creator>Jane Doe</dc:creator></item>
          </channel>
        </rss>
      XML

      expect(described_class.get_item_author(item)).to eq("Jane Doe")
    end

    it "unwraps an Atom author element" do
      item = parsed_item(<<~XML)
        <feed xmlns="http://www.w3.org/2005/Atom">
          <title>t</title><id>urn:x</id><updated>2026-06-01T00:00:00Z</updated>
          <entry>
            <title>a</title><id>urn:y</id><updated>2026-06-01T00:00:00Z</updated>
            <author><name>Jane Doe</name></author>
          </entry>
        </feed>
      XML

      expect(described_class.get_item_author(item)).to eq("Jane Doe")
    end

    it "returns nil when no author is present" do
      item = parsed_item(<<~XML)
        <rss version="2.0">
          <channel><title>t</title><link>https://x.com</link><description>d</description>
            <item><title>a</title></item>
          </channel>
        </rss>
      XML

      expect(described_class.get_item_author(item)).to be_nil
    end
  end

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
