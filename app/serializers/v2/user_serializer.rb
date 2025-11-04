# frozen_string_literal: true

module V2
  class UserSerializer
    include JSONAPI::Serializer

    set_key_transform :camel_lower

    attributes :email, :first_name, :last_name, :role, :created_at, :updated_at

    attribute :full_name do |user|
      user.full_name
    end
  end
end
