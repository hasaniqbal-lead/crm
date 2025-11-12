source "https://rubygems.org"

ruby "3.3.6"

##-- base gems for rails --##
gem "rails", "~> 7.1.5"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "bootsnap", require: false

##-- redis and background jobs --##
gem "redis", ">= 4.0.1"
gem "sidekiq", ">= 7.0"

##-- authentication & authorization --##
gem "devise", ">= 4.9.4"
gem "devise_token_auth", ">= 1.2.3"
gem "jwt"
gem "pundit"
gem "bcrypt", "~> 3.1.7"

##-- CORS for API --##
gem "rack-cors"

##-- helpers --##
gem "jbuilder"
gem "kaminari"

##-- social media integrations --##
gem "facebook-messenger"
gem "koala" # facebook client
gem "twilio-ruby" # for WhatsApp via Twilio
gem "httparty" # for Instagram Graph API

##-- validation --##
gem "telephone_number"
gem "valid_email2"

##-- timezone --##
gem "tzinfo-data", platforms: %i[ windows jruby ]

group :development, :test do
  gem "debug", platforms: %i[ mri windows ]
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "pry-rails"
end

group :development do
  gem "annotate"
end

