require "telegram_error_subscriber"

if Rails.env.production?
  Rails.error.subscribe(TelegramErrorSubscriber.new)
end
