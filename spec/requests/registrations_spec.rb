require "rails_helper"

RSpec.describe "Registrations", type: :request do
  around do |example|
    original_value = ENV["ENABLE_REGISTRATION"]
    example.run
  ensure
    if original_value.nil?
      ENV.delete("ENABLE_REGISTRATION")
    else
      ENV["ENABLE_REGISTRATION"] = original_value
    end
  end

  it "redirects away from the sign-up page when registration is disabled" do
    ENV["ENABLE_REGISTRATION"] = "false"

    get new_user_registration_path

    expect(response).to redirect_to(new_user_session_path)
    expect(flash[:alert]).to eq("Registration is currently disabled.")
  end

  it "does not create a user from a direct sign-up POST when registration is disabled" do
    ENV["ENABLE_REGISTRATION"] = "false"

    expect do
      post user_registration_path, params: {
        user: {
          email: "new-reader@example.com",
          password: "password123",
          password_confirmation: "password123",
          terms_and_conditions: "1"
        }
      }
    end.not_to change(User, :count)

    expect(response).to redirect_to(new_user_session_path)
  end

  it "renders the sign-up page when registration is enabled" do
    ENV["ENABLE_REGISTRATION"] = "true"

    get new_user_registration_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Sign up")
  end
end
