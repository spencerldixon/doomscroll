class IssueMailer < ApplicationMailer
  def daily_issue
    @issue = params.fetch(:issue)
    @user = @issue.user
    @issue_url = issue_url(@issue, token: @issue.signed_id(purpose: :issue_print))
    @cover_art_svg = CoverArt.new(@issue.id).to_svg
    @articles = issue_articles
    @stats = IssueStats.new(@articles)
    @featured_articles = @articles.first(3).map { |article| article.merge("icon_url" => article_icon_url(article)) }
    @featured_authors = @articles.filter_map { |article| article["author"].presence }.uniq.first(3)

    mail(to: @user.email, subject: "#{@issue.title} issue ##{@issue.number} is off the press")
  end

  private

  def issue_articles
    case @issue.content
    when String
      JSON.parse(@issue.content)
    when Array
      @issue.content
    else
      Array(@issue.content)
    end
  end

  def article_icon_url(article)
    return article["icon_url"] if article["icon_url"].present?

    host = URI.parse(article["url"].to_s).host
    return if host.blank?

    "https://www.google.com/s2/favicons?domain=#{host}&sz=32"
  rescue URI::InvalidURIError
    nil
  end
end
