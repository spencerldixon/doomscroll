class TelegramNotifier
  def self.notify(message, chat_id: default_chat_id, parse_mode: "HTML")
    return unless configured?

    bot.api.send_message(chat_id: ENV["TELEGRAM_CHAT_ID"], text: message, parse_mode: parse_mode)
  rescue => e
    Rails.logger.error("[TelegramNotifier] Failed to send notification: #{e.message}")
  end

  def self.configured?
    ENV["TELEGRAM_BOT_TOKEN"] && ENV["TELEGRAM_CHAT_ID"]
  end

  def self.bot
    Telegram::Bot::Client.new(ENV["TELEGRAM_BOT_TOKEN"])
  end
end
