source "https://rubygems.org"

# Rails defaults

gem "rails", "~> 8.1.3"
gem "propshaft"
gem "sqlite3", ">= 2.1"
gem "puma", ">= 5.0"
gem "jsbundling-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "cssbundling-rails"
gem "jbuilder"
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "bootsnap", require: false
gem "dotenv", "~> 3.2"
gem "kamal", require: false
gem "thruster", require: false
gem "image_processing", "~> 1.2"

# App gems

gem "rack-rewrite"
gem "active_link_to"
gem "devise"
gem "cancancan"
gem "valid_email2"
gem "mission_control-jobs"
gem "telegram-bot-ruby", require: "telegram/bot"
gem "wicked"
gem "ssrf_filter"
gem "rss"
gem "rqrcode"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "rspec-rails"
  gem "factory_bot_rails"
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end
