class FeedQualityAssessorJob < ApplicationJob
  queue_as :default

  def perform(feed)
    quality = FeedQualityAssessor.new(feed.url).rate

    feed.update(quality: quality)
  end
end
