# Sidekiq configuration
Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }

  # Configure multiple queues
  config.queues = %w[default notifications low_priority exports]

  # Configure retry logic per queue
  config.death_handlers << ->(job, _ex) do
    Sidekiq.logger.warn("Job #{job['class']} failed permanently")
  end
end

# Configure cron jobs using sidekiq-cron
if defined?(Sidekiq::Cron)
  Sidekiq::Cron::Job.create(
    name: "task_reminder_job",
    cron: "0 9 * * *", # Daily at 9 AM
    class: "TaskReminderJob"
  ) unless Sidekiq::Cron::Job.find("task_reminder_job")

  Sidekiq::Cron::Job.create(
    name: "task_archival_job",
    cron: "0 2 * * 0", # Weekly on Sunday at 2 AM
    class: "TaskArchivalJob"
  ) unless Sidekiq::Cron::Job.find("task_archival_job")
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
end
