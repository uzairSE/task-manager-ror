# frozen_string_literal: true

module ApiRespondable
  extend ActiveSupport::Concern

  private

  def render_success(data, status: :ok, serializer: nil, include: nil)
    if serializer && data
      options = {}
      options[:include] = include if include

      if data.respond_to?(:each)
        render json: serializer.new(data, options).serializable_hash, status: status
      else
        render json: serializer.new(data, options).serializable_hash, status: status
      end
    else
      render json: { data: data }, status: status
    end
  end

  def render_error(code:, message:, details: {}, status: :unprocessable_entity)
    render json: {
      error: {
        code: code.to_s.upcase,
        message: message,
        details: details
      }
    }, status: status
  end

  def render_validation_error(record)
    render_error(
      code: "VALIDATION_ERROR",
      message: "Validation failed",
      details: record.errors.full_messages,
      status: :unprocessable_entity
    )
  end

  def render_not_found(resource: "Resource")
    render_error(
      code: "NOT_FOUND",
      message: "#{resource} not found",
      details: {},
      status: :not_found
    )
  end

  def render_unauthorized(message: "You need to be authenticated to perform this action")
    render_error(
      code: "UNAUTHORIZED",
      message: message,
      details: {},
      status: :unauthorized
    )
  end

  def render_forbidden(message: "You are not authorized to perform this action")
    render_error(
      code: "FORBIDDEN",
      message: message,
      details: {},
      status: :forbidden
    )
  end
end
