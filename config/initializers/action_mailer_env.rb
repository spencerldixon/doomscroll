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
