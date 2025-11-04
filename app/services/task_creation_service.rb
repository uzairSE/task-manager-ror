# frozen_string_literal: true

class TaskCreationService < ApplicationService
  def initialize(user:, params:)
    @user = user
    @params = params
  end

  def call
    ActiveRecord::Base.transaction do
      task = @user.created_tasks.build(@params)
      task.status ||= :pending

      if task.save
        # Enqueue notification job if assignee is present (after successful save)
        TaskNotificationJob.perform_async(task.id) if task.assignee_id.present?

        success_result(task)
      else
        failure_result(task.errors.full_messages)
      end
    end
  end
end
