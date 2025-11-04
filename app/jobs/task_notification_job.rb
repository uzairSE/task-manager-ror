# frozen_string_literal: true

class TaskNotificationJob < ApplicationSidekiqJob
  sidekiq_options queue: :default, retry: 3

  def perform(task_id, notification_type: "assignment")
    task = Task.find_by(id: task_id)
    return unless task

    case notification_type
    when "assignment"
      send_assignment_notification(task) if task.assignee
    when "completion"
      send_completion_notification(task) if task.creator
    end
  end

  private

  def send_assignment_notification(task)
    # In a real application, this would send an email
    # For now, we'll just log it
    Rails.logger.info("Sending assignment notification to #{task.assignee.email} for task #{task.id}")
    # TaskMailer.assignment_notification(task).deliver_now
  end

  def send_completion_notification(task)
    Rails.logger.info("Sending completion notification to #{task.creator.email} for task #{task.id}")
    # TaskMailer.completion_notification(task).deliver_now
  end
end
