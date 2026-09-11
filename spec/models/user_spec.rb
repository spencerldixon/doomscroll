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

  describe ".registration_enabled?" do
    it "is true when no user exists yet" do
      ENV["ENABLE_REGISTRATION"] = "true"

      expect(User.registration_enabled?).to be true
    end

    it "is false once a user exists, regardless of ENABLE_REGISTRATION" do
      ENV["ENABLE_REGISTRATION"] = "true"
      User.create!(
        email: "reader@example.com",
        password: "password123",
        confirmed_at: Time.current
      )

      expect(User.registration_enabled?).to be false
    end

    it "is false when disabled via ENV even with no users" do
      ENV["ENABLE_REGISTRATION"] = "false"

      expect(User.registration_enabled?).to be false
    end
  end

  include ActiveSupport::Testing::TimeHelpers

  describe "#next_issue_date" do
    # Monday 2026-06-22; Wednesday is wday 3.
    around { |example| travel_to(Time.zone.local(2026, 6, 22, 9, 0, 0)) { example.run } }

    it "is the next occurrence of the delivery day for a user who has never been delivered to" do
      user = build_user(delivery_day: 3, delivery_frequency: "monthly")

      expect(user.next_issue_date).to eq(Date.new(2026, 6, 24))
      expect(user.days_until_next_issue).to eq(2)
    end

    it "is the following week for a weekly user delivered to last week" do
      user = build_user(delivery_day: 3, delivery_frequency: "weekly", last_delivered_on: Date.new(2026, 6, 17))

      expect(user.next_issue_date).to eq(Date.new(2026, 6, 24))
    end

    it "skips a week for a biweekly user delivered to last week" do
      user = build_user(delivery_day: 3, delivery_frequency: "biweekly", last_delivered_on: Date.new(2026, 6, 17))

      expect(user.next_issue_date).to eq(Date.new(2026, 7, 1))
    end

    it "lands four weeks out for a monthly user delivered to last week" do
      user = build_user(delivery_day: 3, delivery_frequency: "monthly", last_delivered_on: Date.new(2026, 6, 17))

      expect(user.next_issue_date).to eq(Date.new(2026, 7, 15))
    end
  end

  describe "#delivery_cadence_label" do
    it "describes each frequency in terms of the delivery day" do
      expect(build_user(delivery_day: 3, delivery_frequency: "weekly").delivery_cadence_label)
        .to eq("Every Wednesday")
      expect(build_user(delivery_day: 3, delivery_frequency: "biweekly").delivery_cadence_label)
        .to eq("Every other Wednesday")
      expect(build_user(delivery_day: 3, delivery_frequency: "monthly").delivery_cadence_label)
        .to eq("Every 4 weeks on Wednesday")
    end
  end

  def build_user(delivery_day:, delivery_frequency: "weekly", last_delivered_on: nil)
    user = User.create!(
      email: "reader#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )
    user.create_zine_preference!(
      zine_name: "Daily Zine",
      delivery_day: delivery_day,
      delivery_frequency: delivery_frequency,
      last_delivered_on: last_delivered_on
    )
    user
  end
end
