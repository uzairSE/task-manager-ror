# frozen_string_literal: true

# Configure Bullet gem for N+1 query detection
# This helps identify and fix N+1 query problems during development and testing

if defined?(Bullet)
  Bullet.enable = true
  Bullet.alert = true
  Bullet.bullet_logger = true
  Bullet.console = true
  Bullet.rails_logger = true
  Bullet.add_footer = true

  # Only enable in development and test environments
  Bullet.enable = false if Rails.env.production?

  # Custom configuration for better detection
  Bullet.stacktrace_includes = [ "app/controllers", "app/services", "app/models" ]
  Bullet.stacktrace_excludes = [ "lib/bullet", "vendor/bundle" ]
end
