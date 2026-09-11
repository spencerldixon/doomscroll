require "rails_helper"

RSpec.describe DeliveryChannels do
  describe ".resolve_undecided" do
    let(:preference) { ZinePreference.new(telegram_bot_token: nil, telegram_chat_id: nil) }

    it "prefers the reader's own Telegram bot when they've set one up" do
      preference.telegram_bot_token = "bot-token"
      preference.telegram_chat_id = "12345"

      expect(described_class.resolve_undecided(preference)).to eq("telegram")
    end

    it "falls back to email once the server has SMTP configured" do
      allow(described_class).to receive(:email_available?).and_return(true)

      expect(described_class.resolve_undecided(preference)).to eq("email")
    end

    it "falls back to the server's Telegram bot when there's no SMTP but a bot is configured" do
      allow(described_class).to receive(:email_available?).and_return(false)
      allow(described_class).to receive(:telegram_available?).and_return(true)

      expect(described_class.resolve_undecided(preference)).to eq("telegram")
    end

    it "returns nil when nothing is configured yet" do
      allow(described_class).to receive(:email_available?).and_return(false)
      allow(described_class).to receive(:telegram_available?).and_return(false)

      expect(described_class.resolve_undecided(preference)).to be_nil
    end
  end
end
