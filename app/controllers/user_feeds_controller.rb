class UserFeedsController < ApplicationController
  def create
    # Subscribe to a feed
    feed = Feed.find(params[:feed_id])
    current_user.user_feeds.find_or_create_by(feed_id: feed.id)
    redirect_to feeds_path, notice: "Subscribed to #{feed.name}."
  end

  def destroy
    # Unsubscribe to a feed
    feed = Feed.find(params[:feed_id])
    current_user.user_feeds.where(feed_id: feed.id).delete_all
    redirect_to feeds_path, notice: "Unsubscribed from #{feed.name}."
  end
end
