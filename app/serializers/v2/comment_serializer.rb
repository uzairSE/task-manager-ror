# frozen_string_literal: true

module V2
  class CommentSerializer
    include JSONAPI::Serializer

    set_key_transform :camel_lower

    attributes :content, :created_at, :updated_at

    belongs_to :user, serializer: V2::UserSerializer
  end
end
