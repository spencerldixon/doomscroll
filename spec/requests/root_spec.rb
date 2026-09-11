require "rails_helper"

RSpec.describe "Root", type: :request do
  it "redirects to sign up when no user exists yet" do
    get root_path

    expect(response).to redirect_to(new_user_registration_path)
  end

  it "redirects to login once a user exists" do
    User.create!(
      email: "reader@example.com",
      password: "password123",
      terms_and_conditions: true,
      confirmed_at: Time.current
    )

    get root_path

    expect(response).to redirect_to(new_user_session_path)
  end
end
