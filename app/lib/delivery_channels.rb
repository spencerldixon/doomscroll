module DeliveryChannels
  def self.email_available?
    ENV["SMTP_ADDRESS"].present?
  end

  def self.telegram_available?
    TelegramNotifier.configured?
  end

  # A reader who picked "none" hasn't set up delivery yet. Rather than
  # staying silent forever, they pick up whichever channel becomes
  # available: their own Telegram bot first (a deliberate action on their
  # part), then whatever the server has configured.
  def self.resolve_undecided(preference)
    return "telegram" if preference.telegram_bot_token.present? && preference.telegram_chat_id.present?
    return "email" if email_available?
    return "telegram" if telegram_available?

    nil
  end
end
