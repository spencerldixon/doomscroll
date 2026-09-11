require "rails_helper"

RSpec.describe ZinePreference, type: :model do
  let(:wednesday) { Date.new(2026, 6, 24) }

  describe "#due_on?" do
    it "is not due on a day other than the delivery day" do
      preference = build_preference(delivery_day: wednesday.wday)

      expect(preference.due_on?(wednesday + 1)).to be(false)
    end

    it "is due on the delivery day when nothing has been delivered yet" do
      preference = build_preference(delivery_day: wednesday.wday, last_delivered_on: nil)

      expect(preference.due_on?(wednesday)).to be(true)
    end

    it "is not due again on the day it was just delivered" do
      preference = build_preference(delivery_day: wednesday.wday, last_delivered_on: wednesday)

      expect(preference.due_on?(wednesday)).to be(false)
    end

    it "is due a week after the last weekly delivery" do
      preference = build_preference(
        delivery_day: wednesday.wday,
        delivery_frequency: "weekly",
        last_delivered_on: wednesday - 7
      )

      expect(preference.due_on?(wednesday)).to be(true)
    end

    it "is not due one week after the last biweekly delivery" do
      preference = build_preference(
        delivery_day: wednesday.wday,
        delivery_frequency: "biweekly",
        last_delivered_on: wednesday - 7
      )

      expect(preference.due_on?(wednesday)).to be(false)
    end

    it "is due two weeks after the last biweekly delivery" do
      preference = build_preference(
        delivery_day: wednesday.wday,
        delivery_frequency: "biweekly",
        last_delivered_on: wednesday - 14
      )

      expect(preference.due_on?(wednesday)).to be(true)
    end

    it "is not due three weeks after the last monthly delivery" do
      preference = build_preference(
        delivery_day: wednesday.wday,
        delivery_frequency: "monthly",
        last_delivered_on: wednesday - 21
      )

      expect(preference.due_on?(wednesday)).to be(false)
    end

    it "is due four weeks after the last monthly delivery" do
      preference = build_preference(
        delivery_day: wednesday.wday,
        delivery_frequency: "monthly",
        last_delivered_on: wednesday - 28
      )

      expect(preference.due_on?(wednesday)).to be(true)
    end

    it "ignores issues that were not scheduled deliveries" do
      preference = build_preference(delivery_day: wednesday.wday, last_delivered_on: nil)
      preference.user.issues.create!(content: [])

      expect(preference.due_on?(wednesday)).to be(true)
    end
  end

  describe "re-anchoring on a frequency change" do
    it "restarts the cycle from today when the frequency changes" do
      preference = build_preference(delivery_frequency: "weekly", last_delivered_on: wednesday - 70)

      preference.update!(delivery_frequency: "monthly")

      expect(preference.last_delivered_on).to eq(Date.current)
    end

    it "restarts the cycle from today when the frequency changes on a never-delivered reader" do
      preference = build_preference(delivery_frequency: "weekly", last_delivered_on: nil)

      preference.update!(delivery_frequency: "biweekly")

      expect(preference.last_delivered_on).to eq(Date.current)
    end

    it "leaves the cycle alone when only the delivery day changes" do
      preference = build_preference(delivery_frequency: "weekly", last_delivered_on: wednesday - 7)

      preference.update!(delivery_day: 5)

      expect(preference.last_delivered_on).to eq(wednesday - 7)
    end

    it "does not anchor a reader who is choosing a frequency for the first time" do
      preference = build_preference(delivery_frequency: "monthly")

      expect(preference.last_delivered_on).to be_nil
    end
  end

  describe "delivery_frequency" do
    it "defaults to weekly" do
      expect(build_preference.delivery_frequency).to eq("weekly")
    end

    it "rejects an unknown frequency instead of raising" do
      preference = build_preference

      preference.delivery_frequency = "hourly"

      expect(preference).not_to be_valid
      expect(preference.errors[:delivery_frequency]).to be_present
    end
  end

  describe "delivery_method" do
    it "defaults to email" do
      expect(build_preference.delivery_method).to eq("email")
    end

    it "rejects an unknown delivery method" do
      preference = build_preference
      preference.delivery_method = "carrier_pigeon"

      expect(preference).not_to be_valid
      expect(preference.errors[:delivery_method]).to be_present
    end

    context "when the delivery method is telegram" do
      it "requires a bot token and chat id when the server has none configured" do
        preference = build_preference
        preference.delivery_method = "telegram"

        expect(preference).not_to be_valid
        expect(preference.errors[:base]).to be_present
      end

      it "is valid once a bot token and chat id are set" do
        preference = build_preference
        preference.delivery_method = "telegram"
        preference.telegram_bot_token = "bot-token"
        preference.telegram_chat_id = "12345"

        expect(preference).to be_valid
      end

      it "is valid without per-user credentials when the server already has a bot configured" do
        allow(DeliveryChannels).to receive(:telegram_available?).and_return(true)
        preference = build_preference
        preference.delivery_method = "telegram"

        expect(preference).to be_valid
      end
    end

    it "encrypts the telegram bot token at rest" do
      preference = build_preference
      preference.update!(delivery_method: "telegram", telegram_bot_token: "super-secret", telegram_chat_id: "12345")

      raw_value = ZinePreference.connection.select_value(
        "SELECT telegram_bot_token FROM zine_preferences WHERE id = #{preference.id}"
      )

      expect(raw_value).not_to eq("super-secret")
      expect(preference.reload.telegram_bot_token).to eq("super-secret")
    end
  end

  def build_preference(delivery_day: 3, delivery_frequency: "weekly", last_delivered_on: nil)
    user = User.create!(
      email: "reader#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      password_confirmation: "password123",
      terms_and_conditions: true,
      confirmed_at: Time.current
    )

    user.create_zine_preference!(
      zine_name: "Daily Zine",
      delivery_day: delivery_day,
      delivery_frequency: delivery_frequency,
      last_delivered_on: last_delivered_on
    )
  end
end
