# frozen_string_literal: true

module Api
  module V1
    class UsersController < BaseController
      before_action :set_user, only: [ :show, :update, :destroy ]

      def index
        authorize User
        users = policy_scope(User)
        users = users.where(role: params[:role]) if params[:role].present?

        paginated_users = paginate(users)
        render_success(paginated_users, serializer: UserSerializer)
      end

      def show
        authorize @user
        render_success(@user, serializer: UserSerializer)
      end

      def update
        authorize @user

        if @user.update(user_params)
          render_success(@user, serializer: UserSerializer)
        else
          render_validation_error(@user)
        end
      end

      def destroy
        authorize @user
        @user.destroy
        render json: { message: "User deleted successfully" }, status: :ok
      end

      private

      def set_user
        @user = User.find(params[:id])
      end

      def user_params
        permitted = [ :email, :first_name, :last_name ]
        permitted << :role if current_user&.admin?
        params.permit(permitted)
      end
    end
  end
end
