require "rails_helper"

RSpec.describe ArticleFetcher do
  Content = Struct.new(:content)
  FeedDoc = Struct.new(:items)
  FeedItem = Struct.new(:title, :content, :description, :link, :pubDate, :author)

  let(:user) do
    User.create!(
      email: "reader@example.com",
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )
  end

  let(:feed) do
    Feed.create!(
      name: "Example Feed",
      url: "https://example.com/rss",
      quality: "full"
    )
  end

  let(:other_feed) do
    Feed.create!(
      name: "Other Feed",
      url: "https://other.example.com/rss",
      quality: "full"
    )
  end

  before do
    user.feeds << feed
  end

  describe "#get_random_articles" do
    it "returns random full-feed articles published after the since date" do
      recent = article_item("Recent", "https://example.com/recent", 1.day.ago)
      older = article_item("Older", "https://example.com/older", 2.weeks.ago)

      allow(FeedUtils).to receive(:get_feed)
        .with(feed.url)
        .and_return(FeedDoc.new([ recent, older ]))

      articles = described_class.new(user, 1, 1, 1.week.ago).get_random_articles

      expect(articles.map(&:title)).to eq([ "Recent" ])
      expect(articles.first).to have_attributes(
        body: "<p>Recent body</p>",
        url: "https://example.com/recent",
        source: "Example Feed",
        author: "Example Author"
      )
    end

    it "mixes articles across feeds before taking another article from the same feed" do
      user.feeds << other_feed

      allow(FeedUtils).to receive(:get_feed)
        .with(feed.url)
        .and_return(FeedDoc.new([
          article_item("First Feed A", "https://example.com/a", 1.day.ago),
          article_item("First Feed B", "https://example.com/b", 1.day.ago)
        ]))
      allow(FeedUtils).to receive(:get_feed)
        .with(other_feed.url)
        .and_return(FeedDoc.new([
          article_item("Other Feed A", "https://other.example.com/a", 1.day.ago),
          article_item("Other Feed B", "https://other.example.com/b", 1.day.ago)
        ]))

      articles = described_class.new(user, 2, 3, 1.week.ago).get_random_articles

      expect(articles.size).to eq(3)
      expect(articles.first(2).map(&:source).uniq).to contain_exactly("Example Feed", "Other Feed")
    end

    it "raises when there are not enough eligible articles" do
      allow(FeedUtils).to receive(:get_feed)
        .with(feed.url)
        .and_return(FeedDoc.new([ article_item("Recent", "https://example.com/recent", 1.day.ago) ]))

      fetcher = described_class.new(user, 1, 2, 1.week.ago)

      expect { fetcher.get_random_articles }
        .to raise_error(RuntimeError, "Not enough articles found: requested 2, found 1")
    end

    it "returns serializable article hashes" do
      allow(FeedUtils).to receive(:get_feed)
        .with(feed.url)
        .and_return(FeedDoc.new([ article_item("Recent", "https://example.com/recent", 1.day.ago) ]))

      articles = described_class.new(user, 1, 1, 1.week.ago).get_random_article_hashes

      expect(articles.first).to include(
        title: "Recent",
        body: "<p>Recent body</p>",
        url: "https://example.com/recent",
        source: "Example Feed",
        author: "Example Author"
      )
      expect(articles.first[:published_at]).to be_present
    end
  end

  def article_item(title, url, published_at)
    FeedItem.new(
      title,
      Content.new("<p>#{title} body</p>"),
      nil,
      url,
      published_at,
      "Example Author"
    )
  end
end
