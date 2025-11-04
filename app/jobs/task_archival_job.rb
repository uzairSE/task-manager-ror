# frozen_string_literal: true

class TaskArchivalJob < ApplicationSidekiqJob
  sidekiq_options queue: :low_priority, retry: 3

  def perform
    # Find completed tasks older than 30 days
    cutoff_date = 30.days.ago

    # Use update_all for batch updates instead of individual saves
    # This is much more efficient for bulk operations
    archived_count = Task.completed
                          .where("completed_at < ?", cutoff_date)
                          .update_all(status: :archived, updated_at: Time.current)

    Rails.logger.info("Archived #{archived_count} completed tasks older than 30 days")
  end
end
