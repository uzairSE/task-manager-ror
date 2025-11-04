# frozen_string_literal: true

# Base class for Sidekiq jobs
class ApplicationSidekiqJob
  include Sidekiq::Job
end
