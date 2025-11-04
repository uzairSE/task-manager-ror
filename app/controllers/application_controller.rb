class ApplicationController < ActionController::API
  def route_not_found
    render json: {
      error: {
        code: "NOT_FOUND",
        message: "Route not found",
        details: {}
      }
    }, status: :not_found
  end
end
