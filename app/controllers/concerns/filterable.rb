# frozen_string_literal: true

module Filterable
  extend ActiveSupport::Concern

  private

  def apply_filters(scope, filter_params)
    # Filter by assignee
    if filter_params[:assignee_id].present?
      assignee = User.find_by_id(filter_params[:assignee_id])
      scope = scope.assigned_to(assignee) if assignee
    end

    # Filter by creator
    if filter_params[:creator_id].present?
      creator = User.find_by_id(filter_params[:creator_id])
      scope = scope.created_by(creator) if creator
    end

    # Filter by status
    scope = scope.by_status(filter_params[:status]) if filter_params[:status].present?

    # Filter by priority
    scope = scope.by_priority(filter_params[:priority]) if filter_params[:priority].present?

    scope
  end

  def apply_sorting(scope, sort_param)
    case sort_param
    when "recent"
      scope.recent
    when "oldest"
      scope.order(created_at: :asc)
    when "due_date"
      scope.order(due_date: :asc)
    else
      scope
    end
  end
end
