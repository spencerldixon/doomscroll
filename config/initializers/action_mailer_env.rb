mailer_url_options = {
  host: ENV.fetch("MAILER_DEFAULT_URL_HOST", "localhost")
}

default_mailer_port = Rails.env.development? ? 3000 : nil
mailer_port = ENV.fetch("MAILER_DEFAULT_URL_PORT", default_mailer_port).presence
mailer_url_options[:port] = mailer_port.to_i if mailer_port.present?

Rails.application.config.action_mailer.default_url_options = mailer_url_options

smtp_address = ENV.fetch("SMTP_ADDRESS", nil)
if smtp_address.present?
  Rails.application.config.action_mailer.delivery_method = :smtp
  Rails.application.config.action_mailer.perform_deliveries = true
  Rails.application.config.action_mailer.raise_delivery_errors = true
  Rails.application.config.action_mailer.smtp_settings = {
    address: smtp_address,
    port: ENV.fetch("SMTP_PORT", 587).to_i,
    domain: ENV.fetch("SMTP_DOMAIN", nil),
    user_name: ENV.fetch("SMTP_USERNAME", nil),
    password: ENV.fetch("SMTP_PASSWORD", nil),
    authentication: :plain,
    enable_starttls_auto: true
  }.compact
end
