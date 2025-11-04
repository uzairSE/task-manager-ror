# frozen_string_literal: true

class TaskAssignmentService < ApplicationService
  def initialize(task:, assignee:, assigned_by:)
    @task = task
    @assignee = assignee
    @assigned_by = assigned_by
  end

  def call
    # Check authorization
    policy = TaskPolicy.new(@assigned_by, @task)
    return failure_result([ "You are not authorized to assign tasks" ]) unless policy.assign?

    # Validate assignee exists
    return failure_result([ "Assignee not found" ]) unless @assignee.present?

    ActiveRecord::Base.transaction do
      # Update task assignee
      @task.assignee = @assignee

      if @task.save
        # Send notification to new assignee (after successful save)
        TaskNotificationJob.perform_async(@task.id)

        success_result(@task)
      else
        failure_result(@task.errors.full_messages)
      end
    end
  end
end
