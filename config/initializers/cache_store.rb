# frozen_string_literal: true

# Configure Redis as the cache store for better performance
# Uses Redis database 1 (Sidekiq uses database 0)

if Rails.env.production? || ENV["USE_REDIS_CACHE"] == "true"
  # Build Redis URL with database 1 for cache (Sidekiq uses 0)
  base_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")
  cache_url = base_url.sub(%r{/\d+$}, "/1")

  Rails.application.config.cache_store = :redis_cache_store, {
    url: cache_url,
    namespace: "task_management_cache",
    expires_in: 1.hour,
    reconnect_attempts: 3,
    error_handler: ->(method:, returning:, exception:) {
      Rails.logger.warn("Redis cache error: #{exception.class} - #{exception.message}")
    }
  }
elsif Rails.env.development?
  # Use memory store by default in development
  if ENV["USE_REDIS_CACHE"] == "true"
    base_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/0")
    cache_url = base_url.sub(%r{/\d+$}, "/1")

    Rails.application.config.cache_store = :redis_cache_store, {
      url: cache_url,
      namespace: "task_management_cache_dev",
      expires_in: 1.hour
    }
  else
    Rails.application.config.cache_store = :memory_store
  end
else
  # Test environment - use memory store for cache tests to work
  Rails.application.config.cache_store = :memory_store
end
