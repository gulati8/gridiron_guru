require 'sidekiq'

# Use local Redis in development, environment variable in production
redis_url = if Rails.env.development?
              "redis://localhost:6379/0"
            else
              ENV.fetch("REDIS_URL", "redis://localhost:6379/0")
            end

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end