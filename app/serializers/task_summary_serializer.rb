# frozen_string_literal: true

# Lightweight serializer for dashboard endpoints that doesn't include comments
# to avoid unnecessary queries
class TaskSummarySerializer
  include JSONAPI::Serializer

  attributes :title, :description, :status, :priority, :due_date, :completed_at, :created_at, :updated_at

  belongs_to :creator, serializer: UserSerializer
  belongs_to :assignee, serializer: UserSerializer, optional: true
  # Note: comments relationship intentionally omitted to prevent N+1 queries
end
