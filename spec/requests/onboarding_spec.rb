require 'rails_helper'

RSpec.describe "Onboarding", type: :request do
  let(:user) do
    User.create!(
      email: "test@example.com",
      password: "password123",
      terms_and_conditions: true,
      confirmed_at: Time.current
    )
  end

  let!(:feeds) do
    4.times.map { |i| Feed.create!(name: "Feed #{i}", url: "https://example.com/feed#{i}.xml") }
  end

  before { sign_in user }

  describe "PUT /onboarding/name" do
    it "saves the zine name and moves to the feeds step" do
      put onboarding_path(:name), params: { zine_name: "My Zine" }

      expect(response).to redirect_to(onboarding_path(:feeds))
      expect(user.reload.zine_preference.zine_name).to eq("My Zine")
    end

    it "re-renders the step when zine name is blank" do
      put onboarding_path(:name), params: { zine_name: "" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(user.reload.zine_preference&.zine_name).to be_blank
    end
  end

  describe "PUT /onboarding/feeds" do
    it "saves the feeds and moves to the delivery step when at least 3 feeds selected" do
      put onboarding_path(:feeds), params: { feed_ids: feeds.first(3).map(&:id) }

      expect(response).to redirect_to(onboarding_path(:delivery))
      expect(user.reload.feed_ids).to match_array(feeds.first(3).map(&:id))
    end

    it "re-renders the step when fewer than 3 feeds selected" do
      put onboarding_path(:feeds), params: { feed_ids: feeds.first(2).map(&:id) }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(user.reload.feed_ids).to be_empty
    end

    it "re-renders the step when no feeds selected" do
      put onboarding_path(:feeds)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(user.reload.feed_ids).to be_empty
    end
  end

  describe "GET /onboarding/complete" do
    it "describes the cadence the user picked" do
      user.create_zine_preference!(zine_name: "My Zine", delivery_day: 3, delivery_frequency: "biweekly")

      get onboarding_complete_path

      expect(response.body).to include("Every other Wednesday")
    end
  end

  describe "PUT /onboarding/delivery" do
    before { user.create_zine_preference!(zine_name: "My Zine") }

    it "saves the delivery day and completes the wizard" do
      put onboarding_path(:delivery), params: { delivery_day: 0, delivery_frequency: "weekly" }

      expect(response).to redirect_to(onboarding_complete_path)
      expect(user.reload.zine_preference.delivery_day).to eq(0)
    end

    it "saves the chosen delivery frequency" do
      put onboarding_path(:delivery), params: { delivery_day: 0, delivery_frequency: "biweekly" }

      expect(response).to redirect_to(onboarding_complete_path)
      expect(user.reload.zine_preference.delivery_frequency).to eq("biweekly")
    end

    it "re-renders the step when no frequency selected" do
      put onboarding_path(:delivery), params: { delivery_day: 0 }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(user.reload.zine_preference.delivery_day).to be_nil
    end

    it "rejects an unknown delivery frequency" do
      put onboarding_path(:delivery), params: { delivery_day: 0, delivery_frequency: "hourly" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(user.reload.zine_preference.delivery_day).to be_nil
    end

    it "offers every frequency on the step" do
      get onboarding_path(:delivery)

      expect(response.body).to include("Every week", "Every 2 weeks", "Every 4 weeks")
    end

    it "re-renders the step when no delivery day selected" do
      put onboarding_path(:delivery), params: { delivery_frequency: "weekly" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(user.reload.zine_preference.delivery_day).to be_nil
    end

    it "rejects an invalid delivery day" do
      put onboarding_path(:delivery), params: { delivery_day: 9, delivery_frequency: "weekly" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(user.reload.zine_preference.delivery_day).to be_nil
    end
  end
end
