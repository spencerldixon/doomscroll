require "ssrf_filter"

class FeedFetchJob < ApplicationJob
  queue_as :default

  def perform(feed_id)
    feed = Feed.find_by(id: feed_id)
    return unless feed

    response = safe_get(feed.url)
    return unless response

    body         = response.body
    content_type = response["Content-Type"].to_s

    if content_type.include?("html")
      doc = Nokogiri::HTML(body)
      feed_href = doc.at_css('link[rel="alternate"][type="application/rss+xml"]')&.attr("href") ||
                  doc.at_css('link[rel="alternate"][type="application/atom+xml"]')&.attr("href")
      return unless feed_href

      feed_href = URI.join(feed.url, feed_href).to_s unless feed_href.match?(/\Ahttps?:\/\//i)
      response  = safe_get(feed_href)
      return unless response

      body = response.body
      feed.update_column(:url, feed_href)
    end

    doc = Nokogiri::XML(body)
    doc.remove_namespaces!

    name = doc.at_xpath("//channel/title")&.text&.strip ||
           doc.at_xpath("//feed/title")&.text&.strip

    description = doc.at_xpath("//channel/description")&.text&.strip ||
                  doc.at_xpath("//feed/subtitle")&.text&.strip ||
                  doc.at_xpath("//feed/description")&.text&.strip

    feed.update(
      name: name.presence || feed.url,
      description: description.presence,
      domain: Feed.normalize_domain(URI.parse(feed.url).host)
    )
  end

  private

  def safe_get(url)
    SsrfFilter.get(url, headers: { "User-Agent" => "Doomscroll/1.0" })
  rescue SsrfFilter::UnsafeIpAddress, SsrfFilter::InvalidUriScheme, SsrfFilter::TooManyRedirects => e
    Rails.logger.warn "[FeedFetchJob] unsafe URL blocked: #{e.message}"
    nil
  rescue => e
    Rails.logger.warn "[FeedFetchJob] fetch failed: #{e.message}"
    nil
  end
end
