# frozen_string_literal: true

module Api
  module V1
    class BaseController < ApplicationController
      include Authenticatable
      include Pundit::Authorization
      include ApiRespondable
      include Filterable

      rescue_from Pundit::NotAuthorizedError, with: :render_forbidden
      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity_handler

      private

      def render_unprocessable_entity_handler(exception)
        render_validation_error(exception.record)
      end

      def paginate(collection)
        page = params[:page]&.to_i || 1
        per_page = [ params[:per_page]&.to_i || 20, 100 ].min # Max 100 per page

        # Simple pagination without Kaminari
        offset = (page - 1) * per_page
        collection.offset(offset).limit(per_page)
      end
    end
  end
end
