require "ssrf_filter"

class ArticleFetcher
  Article = Data.define(:title, :body, :url, :source, :published_at)

  def initialize(feed)
    @feed = feed
  end

  def fetch(since:)
    doc = fetch_and_parse
    items = doc.xpath("//item").presence || doc.xpath("//entry")
    items.filter_map { parse(_1, since:) }
  rescue => e
    Rails.logger.warn "[ArticleFetcher] #{@feed.url}: #{e.message}"
    []
  end

  private

  def fetch_and_parse
    body = SsrfFilter.get(@feed.url, headers: { "User-Agent" => "Doomscroll/1.0" }).body
    doc  = Nokogiri::XML(body)
    doc.remove_namespaces!
    doc
  end

  def parse(item, since:)
    published = parse_date(item)
    return if published && published < since

    Article.new(
      title:        item.at_xpath("title")&.text&.strip,
      body:         extract_content(item),
      url:          item.at_xpath("link")&.text&.strip || item.at_xpath("link/@href")&.text,
      source:       @feed.name,
      published_at: published
    )
  end

  def extract_content(item)
    item.at_xpath("encoded")&.text ||
      item.at_xpath("description")&.text ||
      item.at_xpath("content")&.text ||
      item.at_xpath("summary")&.text ||
      ""
  end

  def parse_date(item)
    raw = item.at_xpath("pubDate")&.text ||
          item.at_xpath("published")&.text ||
          item.at_xpath("updated")&.text
    Time.parse(raw) if raw
  rescue ArgumentError
    nil
  end
end
