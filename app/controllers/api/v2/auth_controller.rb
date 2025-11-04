# frozen_string_literal: true

module Api
  module V2
    class AuthController < BaseController
      skip_before_action :authenticate_user!, only: [ :login, :signup ]

      def login
        user = User.find_by(email: params[:email]&.downcase)

        if user&.valid_password?(params[:password])
          token = ensure_authentication_token(user)
          render_success(
            {
              user: ::V2::UserSerializer.new(user).serializable_hash[:data],
              token: token
            },
            status: :ok
          )
        else
          render_error(
              code: "INVALID_CREDENTIALS",
              message: "Invalid email or password",
            details: {},
            status: :unauthorized
          )
        end
      end

      def logout
        render json: { message: "Logged out successfully" }, status: :ok
      end

      def signup
        user = User.new(user_params)
        user.password = params[:password]
        user.password_confirmation = params[:password_confirmation]
        user.role ||= :member

        if user.save
          token = user.generate_authentication_token!
          render_success(
            {
              user: ::V2::UserSerializer.new(user).serializable_hash[:data],
              token: token
            },
            status: :created
          )
        else
          render_validation_error(user)
        end
      end

      private

      def ensure_authentication_token(user)
        user.authentication_token || user.generate_authentication_token!
      end

      def user_params
        params.permit(:email, :first_name, :last_name)
      end
    end
  end
end
