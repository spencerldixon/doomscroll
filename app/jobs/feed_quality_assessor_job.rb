class FeedQualityAssessorJob < ApplicationJob
  queue_as :default

  def perform(feed)
    rss_feed = GenericFeed.fetch(feed.url)
    quality = FeedQualityAssessor.new(rss_feed).rate

    feed.update(quality: quality)
  end
end
