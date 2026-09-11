require "rails_helper"

RSpec.describe "Preferences", type: :request do
  let(:user) do
    User.create!(
      email: "test@example.com",
      password: "password123",
      terms_and_conditions: true,
      confirmed_at: Time.current
    )
  end

  before do
    user.create_zine_preference!(zine_name: "My Zine", delivery_day: 3)
    feed = Feed.create!(name: "Feed", url: "https://example.com/feed.xml")
    user.user_feeds.create!(feed: feed)
    sign_in user
  end

  it "offers every frequency on the page" do
    get preferences_path

    expect(response.body).to include("Every week", "Every 2 weeks", "Every 4 weeks")
  end

  it "updates the delivery frequency" do
    patch preferences_path, params: { zine_name: "My Zine", delivery_day: 3, delivery_frequency: "monthly" }

    expect(response).to redirect_to(preferences_path)
    expect(user.reload.zine_preference.delivery_frequency).to eq("monthly")
  end

  it "moves the next issue date when the frequency changes" do
    expect {
      patch preferences_path, params: { zine_name: "My Zine", delivery_day: 3, delivery_frequency: "monthly" }
    }.to change { user.reload.next_issue_date }

    expect(user.reload.next_issue_date).to eq(Date.current + 28 + ((3 - (Date.current + 28).wday) % 7))
  end

  it "rejects an unknown delivery frequency" do
    patch preferences_path, params: { zine_name: "My Zine", delivery_day: 3, delivery_frequency: "hourly" }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(user.reload.zine_preference.delivery_frequency).to eq("weekly")
  end
end
