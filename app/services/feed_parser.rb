class FeedParser
  def initialize(feed)
    @feed = feed
  end

  def parse
  end

  def resolve_base_url
    # returns base url from given url
  end

  def resolve_feed(url)
    # finds an rss feed from a url, returns feed url
  end

  def fetch_feed
    # Gets the feed, returns the data
  end

  def parse_feed_name
    # returns feed name
  end

  def parse_feed_description
    # returns feed description
  end
end
