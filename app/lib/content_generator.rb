require 'set'

MAX_WORDS = 10_000
MINIMUM_ARTICLE_WORD_COUNT = 100

class ContentGenerator
  Article = Data.define(:title, :body, :url, :source, :published_at, :author, :word_count)

  def initialize(user:, since: nil, word_count: 10_000)
    @user = user
    @last_issue_date = user.issues.order(:published_at).last&.published_at || 1.week.ago
    @since = since || @last_issue_date
    @word_count = word_count
  end

  def generate(since: @since)
    high_priority_feeds = @user.feeds.where(quality: :full)
    medium_priority_feeds = @user.feeds.where(quality: :partial)

    # Merge feeds but high priority first
    feeds = high_priority_feeds + medium_priority_feeds

    article_pool = []

    articles_by_feed = feeds.each_with_object({}) do |feed, hash|
      rss_feed = FeedUtils.get_feed(feed.url)

      next if rss_feed.nil?

      articles = rss_feed.items.filter_map do |item|
        published_at = FeedUtils.get_item_date(item)
        next unless published_at && published_at > since

        body = FeedUtils.get_content(item).to_s.strip
        word_count = body.split(/\s+/).size

        next if word_count < MINIMUM_ARTICLE_WORD_COUNT 

        Article.new(
          title: FeedUtils.get_title(item).to_s.strip,
          body: body,
          url: FeedUtils.get_link(item).to_s.strip,
          source: feed.name,
          published_at: FeedUtils.get_item_date(item),
          author: FeedUtils.get_item_author(item),
          word_count: word_count
        )
      end

      hash[feed.name] = articles.shuffle unless articles.empty?
    end

    selected = []
    seen_urls = Set.new
    total_words = 0

    loop do
      added_article = false

      articles_by_feed.keys.shuffle.each do |feed_name|
        article = articles_by_feed[feed_name].shift

        next unless article
        next if seen_urls.include?(article.url)

        break if total_words + article.word_count > MAX_WORDS

        selected << article
        seen_urls << article.url
        total_words += article.word_count
        added_article = true
      end

      break unless added_article
      break if total_words >= MAX_WORDS
    end

    selected
  end
end
