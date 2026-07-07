require "cgi"

class TelegramErrorSubscriber
  def report(error, handled:, severity:, context:, source: nil)
    return unless configured?

    message = format_message(error, handled: handled, severity: severity, context: context)
    bot.api.send_message(chat_id: ENV["TELEGRAM_CHAT_ID"], text: message, parse_mode: "HTML")
  rescue => e
    Rails.logger.error("[TelegramErrorSubscriber] Failed to send notification: #{e.message}")
  end

  private

  def configured?
    ENV["TELEGRAM_BOT_TOKEN"] && ENV["TELEGRAM_CHAT_ID"]
  end

  def bot
    Telegram::Bot::Client.new(ENV["TELEGRAM_BOT_TOKEN"])
  end

  def format_message(error, handled:, severity:, context:)
    lines = [
      "🚨 <b>doomscroll.press</b> [#{Rails.env}]",
      "",
      "<b>#{CGI.escapeHTML(error.class.to_s)}</b>",
      CGI.escapeHTML(error.message.truncate(500))
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
