# frozen_string_literal: true

module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  private

  def authenticate_user!
    token = request.headers["Authorization"]&.split(" ")&.last
    @current_user = User.find_by(authentication_token: token) if token

    render_unauthorized unless @current_user
  end

  def current_user
    @current_user
  end

  def render_unauthorized(message: "You need to be authenticated to perform this action")
    # Use ApiRespondable if available, otherwise fallback
    if respond_to?(:render_error, true)
      render_error(code: "UNAUTHORIZED", message: message, details: {}, status: :unauthorized)
    else
      render json: {
        error: {
          code: "UNAUTHORIZED",
          message: message,
          details: {}
        }
      }, status: :unauthorized
    end
  end
end
