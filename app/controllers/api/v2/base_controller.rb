# frozen_string_literal: true

module Api
  module V2
    class BaseController < Api::V1::BaseController
      # V2 uses camelCase instead of snake_case for responses
      # This will be handled in serializers
      # Inherits all concerns from V1::BaseController
    end
  end
end
