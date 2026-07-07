require "rails_helper"

RSpec.describe "Issues", type: :request do
  describe "GET /issues/:id" do
    it "renders an issue with a valid signed print token" do
      user = User.create!(
        email: "reader@example.com",
        password: "password123",
        password_confirmation: "password123",
        terms_and_conditions: true,
        confirmed_at: Time.current
      )
      user.create_zine_preference!(zine_name: "Reader Weekly", delivery_day: Date.current.wday)
      issue = user.issues.create!(content: [])

      get issue_path(issue, token: issue.signed_id(purpose: :issue_print))

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Issue ##{issue.number}")
      expect(response.body).to include("Print")
    end
  end
end
