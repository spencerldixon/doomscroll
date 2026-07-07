require "rails_helper"

RSpec.describe User, type: :model do
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

  describe ".from_omniauth" do
    let(:auth) do
      OmniAuth::AuthHash.new(
        provider: "google_oauth2",
        uid: "google-123",
        info: {
          email: "reader@example.com",
          name: "Reader",
          image: "https://example.com/avatar.png"
        }
      )
    end

    it "does not create a new user when registration is disabled" do
      ENV["ENABLE_REGISTRATION"] = "false"

      expect do
        @user = described_class.from_omniauth(auth)
      end.not_to change(User, :count)

      expect(@user).to be_new_record
      expect(@user.errors[:base]).to include("Registration is currently disabled")
    end

    it "returns an existing OAuth user when registration is disabled" do
      ENV["ENABLE_REGISTRATION"] = "false"
      existing_user = described_class.create!(
        email: "reader@example.com",
        password: "password123",
        provider: "google_oauth2",
        uid: "google-123",
        terms_and_conditions: true,
        confirmed_at: Time.current
      )

      expect(described_class.from_omniauth(auth)).to eq(existing_user)
    end
  end
end
