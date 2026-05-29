class TelegramNotifier
  def self.notify(message, chat_id: default_chat_id, parse_mode: "HTML")
    return unless configured?

    bot.api.send_message(chat_id: chat_id, text: message, parse_mode: parse_mode)
  rescue => e
    Rails.logger.error("[TelegramNotifier] Failed to send notification: #{e.message}")
  end

  def self.configured?
    bot_token.present? && default_chat_id.present?
  end

  def self.bot
    Telegram::Bot::Client.new(bot_token)
  end

  def self.bot_token
    ENV["TELEGRAM_BOT_TOKEN"] || Rails.application.credentials.dig(:telegram, :bot_token)
  end

  def self.default_chat_id
    ENV["TELEGRAM_CHAT_ID"] || Rails.application.credentials.dig(:telegram, :chat_id)
  end
end
