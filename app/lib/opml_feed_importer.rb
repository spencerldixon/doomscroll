require "nokogiri"
require "set"

class OpmlFeedImporter
  InvalidFile = Class.new(StandardError)

  MAX_FILE_SIZE = 1.megabyte
  MAX_FEEDS = 500

  Result = Struct.new(:added_count, :already_subscribed_count, :skipped_count, keyword_init: true) do
    def success?
      added_count.positive? || already_subscribed_count.positive?
    end

    def message
      parts = []
      parts << "Imported #{added_count} #{"feed".pluralize(added_count)}" if added_count.positive?
      parts << "#{already_subscribed_count} already subscribed" if already_subscribed_count.positive?
      parts << "Skipped #{skipped_count} invalid #{"entry".pluralize(skipped_count)}" if skipped_count.positive?

      return parts.join(". ") + "." if parts.any?

      "No feeds were imported."
    end
  end

  def initialize(user, content)
    @user = user
    @content = content.to_s
  end

  def import
    outlines = feed_outlines
    raise InvalidFile, "No feeds found in that OPML file." if outlines.empty?

    added_count = 0
    already_subscribed_count = 0
    skipped_count = 0
    seen_urls = Set.new

    outlines.first(MAX_FEEDS).each do |outline|
      status = import_outline(outline, seen_urls)

      case status
      when :added
        added_count += 1
      when :already_subscribed
        already_subscribed_count += 1
      when :skipped
        skipped_count += 1
      end
    end

    Result.new(
      added_count: added_count,
      already_subscribed_count: already_subscribed_count,
      skipped_count: skipped_count
    )
  end

  private

  attr_reader :user, :content

  def feed_outlines
    raise InvalidFile, "Please upload a valid OPML file." if content.blank?

    doc = Nokogiri::XML(content) { |config| config.nonet.recover }
    raise InvalidFile, "Please upload a valid OPML file." unless doc.root&.name.to_s.casecmp?("opml")

    doc.xpath("//outline").filter_map do |outline|
      url = outline["xmlUrl"].presence || outline["xmlurl"].presence || outline["url"].presence
      next if url.blank?

      {
        url: url.to_s.strip,
        title: (outline["title"].presence || outline["text"].presence).to_s.strip.presence
      }
    end
  end

  def import_outline(outline, seen_urls)
    url = normalized_http_url(outline.fetch(:url))
    return :skipped unless url
    return nil unless seen_urls.add?(url)

    domain = FeedUtils.get_base_domain(url)
    feed = Feed.find_by(url: url) || Feed.find_by(domain: domain)

    if feed
      subscribe_to_existing_feed(feed)
    else
      create_feed_and_subscribe(url, domain, outline[:title])
    end
  rescue ActiveRecord::RecordInvalid
    :skipped
  end

  def normalized_http_url(url)
    normalized_url = FeedUtils.normalize_url(url)
    uri = URI.parse(normalized_url)
    return unless uri.is_a?(URI::HTTP) && uri.host.present?

    normalized_url
  rescue URI::InvalidURIError
    nil
  end

  def subscribe_to_existing_feed(feed)
    user_feed = user.user_feeds.find_or_initialize_by(feed: feed)
    return :already_subscribed if user_feed.persisted?

    user_feed.save!
    :added
  end

  def create_feed_and_subscribe(url, domain, title)
    feed = Feed.create!(url: url, name: title.presence || url, domain: domain)
    user.user_feeds.create!(feed: feed)
    FeedDiscoverJob.perform_later(feed)

    :added
  end
end
