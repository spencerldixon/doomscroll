require "ssrf_filter"
require "rss"

# Helpers for locating and fetching RSS/Atom feeds over HTTP

module FeedUtils
  def self.valid_feed?(url)
    RSS::Parser.parse(URI.open(url).read, false)
    true
  rescue RSS::Error, OpenURI::HTTPError, SocketError
    false
  end

  def self.get_base_domain(url)
    URI.parse(url).host.to_s.sub(/\Awww\./, "").downcase
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
