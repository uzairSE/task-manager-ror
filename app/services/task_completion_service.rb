# frozen_string_literal: true

class TaskCompletionService < ApplicationService
  def initialize(task:, user:)
    @task = task
    @user = user
  end

  def call
    return failure_result([ "Task is already completed" ]) if @task.completed?

    ActiveRecord::Base.transaction do
      @task.status = :completed
      @task.completed_at ||= Time.current

      if @task.save
        # Notify creator if different from current user (after successful save)
        if @task.creator_id != @user.id
          TaskNotificationJob.perform_async(@task.id, notification_type: "completion")
        end

        success_result(@task)
      else
        failure_result(@task.errors.full_messages)
      end
    end
  end
end
