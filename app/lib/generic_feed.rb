require "rss"

# Wraps a parsed RSS/Atom feed (and its items) behind one shape, so callers
# don't need to know which flavor of feed they're looking at.
class GenericFeed
  class Item
    def initialize(raw)
      @raw = raw
    end

    def title
      value = raw.title
      value.respond_to?(:content) ? value.content : value
    end

    def link
      value = raw.link
      value.respond_to?(:href) ? value.href : value
    end

    def content
      # Content is different depending on RSS version and type, this covers them all
      raw.respond_to?(:content) && raw.content&.content ||
      raw.respond_to?(:content_encoded) && raw.content_encoded ||
      raw.description
    end

    def content_text
      Nokogiri::HTML(content.to_s).text
    end

    def author
      %i[author creator dc_creator author_name].each do |method|
        next unless raw.respond_to?(method)

        value = raw.public_send(method)
        next unless value

        value = value.name if value.respond_to?(:name)       # Atom <author><name>
        value = value.content if value.respond_to?(:content) # text node wrapper
        text = value.to_s.strip
        return text unless text.empty?
      end

      nil
    end

    def published_at
      raw.pubDate || raw.dc_date || (raw.respond_to?(:updated) && Time.parse(raw.updated.content))
    end

    private

    attr_reader :raw
  end

  def self.fetch(url)
    body = FeedUtils.safe_get(url)&.body
    return nil unless body

    parse(body)
  end

  def self.parse(body)
    new(RSS::Parser.parse(body, false))
  rescue RSS::NotWellFormedError, RSS::InvalidRSSError
    doc = Nokogiri::XML(body) { |config| config.recover }
    return nil unless doc.root

    new(RSS::Parser.parse(doc.to_xml, false))
  rescue RSS::NotWellFormedError, RSS::InvalidRSSError
    nil
  end

  def initialize(raw)
    @raw = raw
  end

  def title
    name = raw.respond_to?(:channel) ? raw.channel.title : raw.title
    name.respond_to?(:content) ? name.content : name
  end

  def description
    if raw.respond_to?(:channel)
      raw.channel.description
    else
      raw.description&.content || raw.subtitle&.content
    end
  end

  def items
    raw.items.map { |item| Item.new(item) }
  end

  private

  attr_reader :raw
end
