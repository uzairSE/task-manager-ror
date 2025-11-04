# frozen_string_literal: true

module Api
  module V1
    class AuthController < BaseController
      skip_before_action :authenticate_user!, only: [ :login, :signup, :reset_password ]

      def login
        permitted = login_params
        user = User.find_by(email: permitted[:email])

        if user&.valid_password?(permitted[:password])
          token = ensure_authentication_token(user)
          render_success(
            {
              user: UserSerializer.new(user).serializable_hash[:data],
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
        current_user&.invalidate_authentication_token!
        render json: { message: "Logged out successfully" }, status: :ok
      end

      def signup
        user = User.new(user_params)

        if user.save
          token = user.generate_authentication_token!
          render_success(
            {
              user: UserSerializer.new(user).serializable_hash[:data],
              token: token
            },
            status: :created
          )
        else
          render_validation_error(user)
        end
      end

      def reset_password
        permitted = reset_password_params
        user = User.find_by(email: permitted[:email])

        if user
          user.send_reset_password_instructions
          render json: { message: "Password reset instructions sent to your email" }, status: :ok
        else
          # Don't reveal if user exists
          render json: { message: "If the email exists, password reset instructions have been sent" }, status: :ok
        end
      end

      private

      def login_params
        # Permit both flat and nested params
        if params[:auth].present?
          params.require(:auth).permit(:email, :password)
        else
          params.permit(:email, :password)
        end
      end

      def user_params
        params.permit(:email, :password, :password_confirmation, :first_name, :last_name, :role)
      end

      def reset_password_params
        # Permit both flat and nested params
        if params[:auth].present?
          params.require(:auth).permit(:email)
        else
          params.permit(:email)
        end
      end

      def ensure_authentication_token(user)
        user.authentication_token || user.generate_authentication_token!
      end
    end
  end
end
