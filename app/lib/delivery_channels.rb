module DeliveryChannels
  def self.email_available?
    ENV["SMTP_ADDRESS"].present?
  end

  def self.telegram_available?
    TelegramNotifier.configured?
  end
end
