require "rails_helper"

RSpec.describe Issue, type: :model do
  let(:user) do
    User.create!(
      email: "reader@example.com",
      password: "password123",
      password_confirmation: "password123",
      terms_and_conditions: true,
      confirmed_at: Time.current
    )
  end

  describe "content generation" do
    it "stores random fetched articles when content is blank" do
      articles = [
        {
          title: "Fetched Article",
          body: "<p>Fetched body</p>",
          url: "https://example.com/article",
          source: "Example Feed",
          published_at: 1.day.ago.iso8601
        }
      ]

      fetcher = instance_double(ArticleFetcher, get_random_article_hashes: articles)
      allow(ArticleFetcher).to receive(:new).with(user).and_return(fetcher)

      issue = user.issues.create!

      expect(issue.content).to eq(articles.map(&:stringify_keys))
    end

    it "preserves explicit content" do
      content = [
        {
          title: "Manual Article",
          body: "<p>Manual body</p>",
          source: "Manual"
        }
      ]

      expect(ArticleFetcher).not_to receive(:new)

      issue = user.issues.create!(content: content)

      expect(issue.content).to eq(content.map(&:stringify_keys))
    end
  end
end
