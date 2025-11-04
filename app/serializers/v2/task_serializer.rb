# frozen_string_literal: true

module V2
  class TaskSerializer
    include JSONAPI::Serializer

    set_key_transform :camel_lower

    attributes :title, :description, :status, :priority, :due_date, :completed_at, :created_at, :updated_at

    belongs_to :creator, serializer: V2::UserSerializer
    belongs_to :assignee, serializer: V2::UserSerializer, optional: true
    has_many :comments, serializer: V2::CommentSerializer
  end
end
