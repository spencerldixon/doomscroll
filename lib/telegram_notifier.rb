class TelegramNotifier
  def self.notify(message, token: ENV["TELEGRAM_BOT_TOKEN"], chat_id: ENV["TELEGRAM_CHAT_ID"], parse_mode: "HTML")
    return if token.blank? || chat_id.blank?

    Telegram::Bot::Client.new(token).api.send_message(chat_id: chat_id, text: message, parse_mode: parse_mode)
  rescue => e
    Rails.logger.error("[TelegramNotifier] Failed to send notification: #{e.message}")
  end

  def self.configured?
    ENV["TELEGRAM_BOT_TOKEN"].present? && ENV["TELEGRAM_CHAT_ID"].present?
  end
end
