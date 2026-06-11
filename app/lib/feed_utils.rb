require "ssrf_filter"
require "rss"

# A series of helper to assist with fetching and transforming RSS feeds

module FeedUtils
  def self.valid_feed?(url)
    RSS::Parser.parse(URI.open(url).read, false)
    true
  rescue RSS::Error, OpenURI::HTTPError, SocketError
    false
  end

  def self.get_feed(url)
    body = safe_get(url)&.body
    return nil unless body

    RSS::Parser.parse(body, false)
  rescue RSS::NotWellFormedError, RSS::InvalidRSSError
    doc = Nokogiri::XML(body) { |config| config.recover }
    return nil unless doc.root
    RSS::Parser.parse(doc.to_xml, false)
  rescue RSS::NotWellFormedError, RSS::InvalidRSSError
    nil
  end

  def self.get_content(item)
    # Content is different depending on RSS version and type, this allows you to get content regardless of type
    item.respond_to?(:content) && item.content&.content ||
    item.respond_to?(:content_encoded) && item.content_encoded ||
    item.description
  end

  def self.get_content_text(item)
    html = self.get_content(item)
    Nokogiri::HTML(html.to_s).text
  end

  def self.get_title(item)
    title = item.title
    title.respond_to?(:content) ? title.content : title
  end

  def self.get_link(item)
    link = item.link
    link.respond_to?(:href) ? link.href : link
  end

  def self.get_feed_name(feed)
    name = feed.respond_to?(:channel) ? feed.channel.title : feed.title
    name.respond_to?(:content) ? name.content : name
  end

  def self.get_feed_description(feed)
    if feed.respond_to?(:channel)
      feed.channel.description
    else
      feed.description&.content || feed.subtitle&.content
    end
  end

  def self.get_item_author(item)
    %i[author creator dc_creator author_name].each do |method|
      next unless item.respond_to?(method)

      value = item.public_send(method)
      next unless value

      value = value.name if value.respond_to?(:name)       # Atom <author><name>
      value = value.content if value.respond_to?(:content) # text node wrapper
      text = value.to_s.strip
      return text unless text.empty?
    end

    nil
  end

  def self.get_base_domain(url)
    URI.parse(url).host.to_s.sub(/\Awww\./, "").downcase
  end

  def self.get_item_date(item)
    item.pubDate || item.dc_date || (item.respond_to?(:updated) && Time.parse(item.updated.content))
  end

  FEED_PATHS = %w[/feed /rss /feed.xml /rss.xml /atom.xml /index.xml /feed/rss].freeze

  def self.discover_feed_from_url(url)
    url = normalize_url(url)
    response = safe_get(url)
    return nil unless response

    doc = Nokogiri::HTML(response.body)
    feed_href = doc.css("link[rel][type][href]").find do |link|
      link["rel"].to_s.split.include?("alternate") &&
        link["type"].to_s.match?(/rss|atom|xml/i)
    end&.attr("href")

    if feed_href
      return feed_href.match?(/\Ahttps?:\/\//i) ? feed_href : URI.join(url, feed_href).to_s
    end

    base = "#{URI.parse(url).scheme}://#{URI.parse(url).host}"
    FEED_PATHS.each do |path|
      res = safe_get("#{base}#{path}")
      next unless res
      content_type = res["Content-Type"].to_s
      return "#{base}#{path}" if content_type.match?(/xml|rss|atom/i)
    end

    nil
  rescue => e
    Rails.logger.warn "[FeedUtils] discover_feed_from_url failed for #{url}: #{e.message}"
    nil
  end

  def self.normalize_url(url)
    url = url.to_s.strip
    url.match?(/\Ahttps?:\/\//i) ? url : "https://#{url}"
  end

  def self.safe_get(url)
    SsrfFilter.get(url, headers: { "User-Agent" => "Doomscroll/1.0" })
  rescue => e
    Rails.logger.warn "[FeedUtils] fetch failed for #{url}: #{e.message}"
    nil
  end
end
