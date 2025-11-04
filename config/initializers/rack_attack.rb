# frozen_string_literal: true

module Rack
  class Attack
    # Configure cache store for throttling
    self.cache.store = ActiveSupport::Cache::MemoryStore.new

    # Throttle all requests by IP (100 requests per minute)
    throttle("req/ip", limit: 100, period: 1.minute) do |req|
      req.ip unless req.path.start_with?("/up")
    end

    # Throttle API requests more strictly (100 requests per minute per IP)
    throttle("api/ip", limit: 100, period: 1.minute) do |req|
      req.ip if req.path.start_with?("/api")
    end

    # Throttle authentication attempts (10 requests per minute per IP)
    throttle("logins/ip", limit: 10, period: 1.minute) do |req|
      if req.path == "/api/v1/auth/login" || req.path == "/api/v1/auth/signup" ||
        req.path == "/api/v2/auth/login" || req.path == "/api/v2/auth/signup"
        req.ip
      end
    end

    # Block suspicious requests (429 Too Many Requests)
    self.blocklisted_responder = lambda do |env|
      [
        429,
        {
          "Content-Type" => "application/json",
          "Retry-After" => (env["rack.attack.match_data"] || {})[:period].to_s
        },
        [ {
          error: {
            code: "RATE_LIMIT_EXCEEDED",
            message: "Too many requests. Please try again later.",
            details: {}
          }
        }.to_json ]
      ]
    end
  end
end
