# frozen_string_literal: true

# Configure Redis connection for application use
# Create a simple Redis instance (thread-safe in Rails)
REDIS = begin
  Redis.new(
    url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
    timeout: 5,
    reconnect_attempts: 3
  )
rescue => e
  Rails.logger.warn "Redis initialization failed: #{e.message}"
  nil
end

# Test connection on initialization
if REDIS
  begin
    REDIS.ping
  rescue Redis::CannotConnectError, Errno::ECONNREFUSED => e
    Rails.logger.warn "Redis connection failed: #{e.message}. Counters will not be available."
  end
end
