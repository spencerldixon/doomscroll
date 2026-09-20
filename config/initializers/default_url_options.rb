# Host used by every link the app generates: zine emails and the Telegram
# notification sent by DailyIssueGeneratorJob. Falls back to the per-environment
# default in config/environments when APP_HOST is unset.
configured_host = ENV["APP_HOST"].presence || ENV["MAILER_DEFAULT_URL_HOST"].presence

url_options =
  if configured_host
    options = { host: configured_host }
    port = ENV["MAILER_DEFAULT_URL_PORT"].presence
    options[:port] = port.to_i if port
    options
  else
    Rails.logger.warn("APP_HOST is not set; generated links may point at the wrong host") if Rails.env.production?
    Rails.application.config.action_mailer.default_url_options.to_h
  end

url_options[:protocol] = "https" if Rails.application.config.force_ssl

Rails.application.config.action_mailer.default_url_options = url_options
Rails.application.routes.default_url_options = url_options
