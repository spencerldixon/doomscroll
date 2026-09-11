mailer_url_options = {
  host: ENV["MAILER_DEFAULT_URL_HOST"].presence || "localhost"
}

default_mailer_port = Rails.env.development? ? 3000 : nil
mailer_port = ENV["MAILER_DEFAULT_URL_PORT"].presence || default_mailer_port
mailer_url_options[:port] = mailer_port.to_i if mailer_port.present?

Rails.application.config.action_mailer.default_url_options = mailer_url_options

smtp_address = ENV["SMTP_ADDRESS"].presence
if smtp_address
  Rails.application.config.action_mailer.delivery_method = :smtp
  Rails.application.config.action_mailer.perform_deliveries = true
  Rails.application.config.action_mailer.raise_delivery_errors = true
  Rails.application.config.action_mailer.smtp_settings = {
    address: smtp_address,
    port: ENV["SMTP_PORT"].presence&.to_i || 587,
    domain: ENV["SMTP_DOMAIN"].presence,
    user_name: ENV["SMTP_USERNAME"].presence,
    password: ENV["SMTP_PASSWORD"].presence,
    authentication: :plain,
    enable_starttls_auto: true
  }.compact
end
