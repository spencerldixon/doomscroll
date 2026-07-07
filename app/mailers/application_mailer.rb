class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV.fetch("MAILER_DEFAULT_FROM", "from@example.com") }
  layout "mailer"
end
