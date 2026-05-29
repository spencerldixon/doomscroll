require "cgi"

class TelegramErrorSubscriber
  def report(error, handled:, severity:, context:, source: nil)
    return unless configured?

    message = format_message(error, handled: handled, severity: severity, context: context)
    bot.api.send_message(chat_id: chat_id, text: message, parse_mode: "HTML")
  rescue => e
    Rails.logger.error("[TelegramErrorSubscriber] Failed to send notification: #{e.message}")
  end

  private

  def configured?
    bot_token.present? && chat_id.present?
  end

  def bot_token
    ENV["TELEGRAM_BOT_TOKEN"] || Rails.application.credentials.dig(:telegram, :bot_token)
  end

  def chat_id
    ENV["TELEGRAM_CHAT_ID"] || Rails.application.credentials.dig(:telegram, :chat_id)
  end

  def bot
    Telegram::Bot::Client.new(bot_token)
  end

  def format_message(error, handled:, severity:, context:)
    app_name = Rails.application.class.module_parent_name

    lines = [
      "🚨 <b>#{CGI.escapeHTML(app_name)}</b> [#{Rails.env}]",
      "",
      "<b>#{CGI.escapeHTML(error.class.to_s)}</b>",
      CGI.escapeHTML(error.message.truncate(500)),
    ]

    if (req = context[:request])
      lines << ""
      lines << "<b>Request:</b> #{CGI.escapeHTML("#{req.method} #{req.url}")}" rescue nil
    end

    if error.backtrace
      backtrace = error.backtrace.first(5).join("\n")
      lines << ""
      lines << "<b>Backtrace:</b>"
      lines << "<code>#{CGI.escapeHTML(backtrace)}</code>"
    end

    lines << ""
    lines << "<b>Severity:</b> #{severity} | <b>Handled:</b> #{handled}"

    lines.join("\n")
  end
end
