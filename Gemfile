source "https://rubygems.org"

gem "rails", "~> 8.1.3"

# Database
gem "pg", "~> 1.1"

# Web Server
gem "puma", ">= 5.0"

# Timezone data for Windows
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Performance
gem "bootsnap", require: false
gem "oj"

# File Processing (Active Storage)
gem "image_processing", "~> 1.2"

# Authentication
gem "devise"
gem "devise-jwt"

# Authorization
gem "pundit", "~> 2.5"

# Background Jobs
gem "redis"
gem "sidekiq"

# API
gem "rack-cors"

# Pagination
gem "pagy"

# Search
gem "pg_search"

group :development, :test do
  # Debugging
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"

  # Security
  gem "bundler-audit", require: false
  gem "brakeman", require: false

  # Code Quality
  gem "rubocop-rails-omakase", require: false

  # Testing
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
  gem "shoulda-matchers", "~> 8.0"

  # Development
  gem "annotate"
  gem "bullet"
end
