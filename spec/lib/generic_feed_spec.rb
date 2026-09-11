require "rails_helper"

RSpec.describe GenericFeed do
  def parsed_item(xml)
    described_class.parse(xml).items.first
  end

  describe "Item#author" do
    it "returns the author from an RSS 2.0 item" do
      item = parsed_item(<<~XML)
        <rss version="2.0">
          <channel><title>t</title><link>https://x.com</link><description>d</description>
            <item><title>a</title><author>jane@example.com (Jane Doe)</author></item>
          </channel>
        </rss>
      XML

      expect(item.author).to eq("jane@example.com (Jane Doe)")
    end

    it "returns the dc:creator when author is absent" do
      item = parsed_item(<<~XML)
        <rss version="2.0" xmlns:dc="http://purl.org/dc/elements/1.1/">
          <channel><title>t</title><link>https://x.com</link><description>d</description>
            <item><title>a</title><dc:creator>Jane Doe</dc:creator></item>
          </channel>
        </rss>
      XML

      expect(item.author).to eq("Jane Doe")
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

      expect(item.author).to eq("Jane Doe")
    end

    it "returns nil when no author is present" do
      item = parsed_item(<<~XML)
        <rss version="2.0">
          <channel><title>t</title><link>https://x.com</link><description>d</description>
            <item><title>a</title></item>
          </channel>
        </rss>
      XML

      expect(item.author).to be_nil
    end
  end
end
