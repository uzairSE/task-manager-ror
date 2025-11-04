# frozen_string_literal: true

module Api
  module V1
    class TasksController < BaseController
      include Cacheable

      before_action :set_task, only: [ :show, :update, :destroy, :assign, :complete, :export ]

      def index
        authorize Task
        tasks = policy_scope(Task)
        tasks = apply_filters(tasks, params)
        tasks = apply_sorting(tasks, params[:sort])

        # Paginate FIRST, then preload only for paginated records
        paginated_tasks = paginate(tasks)
        paginated_tasks = paginated_tasks.preload(:creator, :assignee)

        render_success(paginated_tasks, serializer: ::TaskSerializer, include: [ :creator, :assignee ])
      end

      def show
        authorize @task
        render_success(@task, serializer: ::TaskSerializer, include: [ :creator, :assignee, :comments ])
      end

      def create
        authorize Task

        result = TaskCreationService.call(user: current_user, params: task_params)

        if result.success?
          invalidate_dashboard_cache(current_user)
          render_success(result.data, serializer: ::TaskSerializer, status: :created)
        else
          render_error(
              code: "VALIDATION_ERROR",
              message: "Task creation failed",
              details: result.errors
          )
        end
      end

      def update
        authorize @task

        if @task.update(task_params)
          invalidate_dashboard_cache(current_user)
          render_success(@task, serializer: ::TaskSerializer)
        else
          render_validation_error(@task)
        end
      end

      def destroy
        authorize @task
        @task.destroy
        invalidate_dashboard_cache(current_user)
        render json: { message: "Task deleted successfully" }, status: :ok
      end

      def assign
        authorize @task

        assignee = User.find_by_id(params[:assignee_id])
        return render_not_found(resource: "Assignee") unless assignee

        result = TaskAssignmentService.call(
          task: @task,
          assignee: assignee,
          assigned_by: current_user
        )

        if result.success?
          invalidate_dashboard_cache(current_user)
          render_success(result.data, serializer: ::TaskSerializer)
        else
          render_error(
              code: "ASSIGNMENT_ERROR",
              message: "Task assignment failed",
              details: result.errors
          )
        end
      end

      def complete
        authorize @task

        result = TaskCompletionService.call(task: @task, user: current_user)

        if result.success?
          invalidate_dashboard_cache(current_user)
          render_success(result.data, serializer: ::TaskSerializer)
        else
          render_error(
              code: "COMPLETION_ERROR",
              message: "Task completion failed",
              details: result.errors
          )
        end
      end

      def export
        authorize @task
        DataExportJob.perform_async(current_user.id)
        render json: { message: "Export job queued. You will receive an email when ready." }, status: :accepted
      end

      def dashboard
        authorize Task

        # Use Redis caching for expensive aggregations
        dashboard_data = fetch_cached_dashboard_data(current_user) do
          # Optimized queries to prevent N+1
          tasks_scope = policy_scope(Task)

          # Total tasks count by status - cached for 5 minutes
          status_counts = tasks_scope.group(:status).count

          # Overdue tasks count - cached for 5 minutes
          overdue_count = tasks_scope.overdue.count

          # User's assigned incomplete tasks with creator info (no N+1)
          # Cache for 2 minutes as this changes more frequently
          assigned_incomplete = tasks_scope
            .where(assignee_id: current_user.id)
            .where.not(status: :completed)
            .preload(:creator)
            .limit(10)

          # Recent activity (last 10 tasks with assignee and creator, no N+1)
          # Cache for 2 minutes as this changes more frequently
          recent_tasks = tasks_scope
            .recent
            .preload(:creator, :assignee)
            .limit(10)

          {
            status_counts: status_counts,
            overdue_count: overdue_count,
            assigned_incomplete_tasks: ::TaskSummarySerializer.new(assigned_incomplete, include: [ :creator ]).serializable_hash,
            recent_activity: ::TaskSummarySerializer.new(recent_tasks, include: [ :creator, :assignee ]).serializable_hash
          }
        end

        render json: { data: dashboard_data }
      end

      def overdue
        authorize Task
        tasks = policy_scope(Task).overdue
        paginated_tasks = paginate(tasks)
        paginated_tasks = paginated_tasks.preload(:creator, :assignee)

        render_success(paginated_tasks, serializer: ::TaskSerializer, include: [ :creator, :assignee ])
      end

      private

      def set_task
        @task = Task.find(params[:id])
      end

      def task_params
        params.permit(:title, :description, :status, :priority, :due_date, :assignee_id)
      end
    end
  end
end
