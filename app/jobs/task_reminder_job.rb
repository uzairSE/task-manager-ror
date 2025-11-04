# frozen_string_literal: true

class TaskReminderJob < ApplicationSidekiqJob
  sidekiq_options queue: :notifications, retry: 5

  def perform
    # Find tasks due in 24 hours that are not completed
    # Optimize query to use indexes and preload assignee to avoid N+1
    due_tomorrow = 24.hours.from_now
    now = Time.current

    # Use optimized query with proper date range and status filtering
    # This will use the composite index on (status, due_date)
    tasks = Task.where("due_date BETWEEN ? AND ?", now, due_tomorrow)
                .where.not(status: [ :completed, :archived ])
                .where.not(assignee_id: nil)
                .preload(:assignee)
                .order(:due_date)

    # Process in batches to avoid memory issues
    tasks.find_each(batch_size: 100) do |task|
      send_reminder(task)
    end
  end

  private

  def send_reminder(task)
    Rails.logger.info("Sending reminder to #{task.assignee.email} for task #{task.id} due on #{task.due_date}")
    # TaskMailer.reminder_notification(task).deliver_now
  end
end
