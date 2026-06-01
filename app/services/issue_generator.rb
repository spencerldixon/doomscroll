class IssueGenerator
  def initialize(user)
    @user  = user
    @since = user.issues.order(:published_at).last&.published_at || 1.week.ago
  end

  def generate
    raise "User has no feeds" if @user.feeds.none?

    articles = @user.feeds
      .flat_map { ArticleFetcher.new(_1).fetch(since: @since) }
      .shuffle

    @user.issues.create!(
      published_at: Time.current,
      content: ArticlePaginator.paginate(articles).map(&:to_h)
    )
  end
end
