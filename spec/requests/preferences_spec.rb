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

  it "switches delivery to Telegram with a bot token and chat id" do
    patch preferences_path, params: {
      zine_name: "My Zine",
      delivery_day: 3,
      delivery_frequency: "weekly",
      delivery_method: "telegram",
      telegram_bot_token: "bot-token",
      telegram_chat_id: "12345"
    }

    expect(response).to redirect_to(preferences_path)
    preference = user.reload.zine_preference
    expect(preference.delivery_method).to eq("telegram")
    expect(preference.telegram_bot_token).to eq("bot-token")
    expect(preference.telegram_chat_id).to eq("12345")
  end

  it "rejects switching to Telegram without a bot token or chat id" do
    patch preferences_path, params: {
      zine_name: "My Zine",
      delivery_day: 3,
      delivery_frequency: "weekly",
      delivery_method: "telegram"
    }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(user.reload.zine_preference.delivery_method).to eq("email")
  end

  it "keeps an already saved bot token when updating other preferences" do
    user.zine_preference.update!(delivery_method: "telegram", telegram_bot_token: "bot-token", telegram_chat_id: "12345")

    patch preferences_path, params: { zine_name: "Renamed Zine", delivery_day: 3, delivery_frequency: "weekly" }

    expect(response).to redirect_to(preferences_path)
    expect(user.reload.zine_preference.telegram_bot_token).to eq("bot-token")
  end
end
