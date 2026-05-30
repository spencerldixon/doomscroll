class FeedsController < ApplicationController
  def index
    @curated_feeds = Feed.curated
    @user_feed_ids = current_user.feed_ids.to_set
    @user_feeds = current_user.user_feeds.includes(:feed).order("feeds.name")
  end

  def create
    url = params[:url].to_s.strip

    begin
      uri = URI.parse(url)
      raise ArgumentError unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
    rescue URI::InvalidURIError, ArgumentError
      redirect_to feeds_path, alert: "Please enter a valid http/https URL." and return
    end

    domain = Feed.normalize_domain(uri.host)

    feed = Feed.find_by(url: url) || Feed.find_by(domain: domain)

    if feed
      current_user.user_feeds.find_or_create_by(feed_id: feed.id)
      redirect_to feeds_path, notice: "Subscribed to #{feed.name}."
    else
      feed = Feed.create!(url: url, name: url, domain: domain, private: true)
      current_user.user_feeds.create!(feed_id: feed.id)
      FeedFetchJob.perform_later(feed.id)
      redirect_to feeds_path, notice: "Feed added — we're fetching its details."
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_to feeds_path, alert: e.message
  end
end
