# frozen_string_literal: true

module Api
  module V1
    class CommentsController < BaseController
      before_action :set_task
      before_action :set_comment, only: [ :destroy ]

      def index
        comments = @task.comments.order(created_at: :desc)
        paginated_comments = paginate(comments)
        paginated_comments = paginated_comments.preload(:user)

        render_success(paginated_comments, serializer: CommentSerializer, include: [ :user ])
      end

      def create
        comment = @task.comments.build(comment_params)
        comment.user = current_user

        if comment.save
          render_success(comment, serializer: CommentSerializer, status: :created, include: [ :user ])
        else
          render_validation_error(comment)
        end
      end

      def destroy
        authorize @comment, policy_class: CommentPolicy
        @comment.destroy
        render json: { message: "Comment deleted successfully" }, status: :ok
      end

      private

      def set_task
        @task = Task.find(params[:task_id])
        authorize @task, :show?
      end

      def set_comment
        @comment = @task.comments.find(params[:id])
      end

      def comment_params
        params.permit(:content)
      end
    end
  end
end
