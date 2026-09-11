# Takes a feed object with just a url, and attempts to validate or discover the rss feed
# If a valid feed is found, we pull the info, assess quality and save it
# If the url is a dud, we self destruct and remove the feed record

class FeedDiscoverJob < ApplicationJob
  queue_as :default

  def perform(feed)
    # Attempt to validate/discover feed from given url
    feed_url =  if FeedUtils.valid_feed?(feed.url)
                  feed.url
    else
                  FeedUtils.discover_feed_from_url(feed.url)
    end

    # Raise if no valid feed found
    raise "Could not find valid feed for #{feed.url}" unless feed_url

    # Grab the feed and fetch details
    rss_feed    = GenericFeed.fetch(feed_url)
    name        = rss_feed.title
    description = rss_feed.description
    domain      = FeedUtils.get_base_domain(feed_url)
    quality     = FeedQualityAssessor.new(rss_feed).rate

    # Update the record
    feed.update!(
      url: feed_url,
      name: name.presence || feed_url,
      description: description.presence,
      domain: domain,
      quality: quality
    )
  rescue StandardError => e
    feed.destroy!

    raise e
  end
end
