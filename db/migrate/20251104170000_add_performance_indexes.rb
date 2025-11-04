# frozen_string_literal: true

class AddPerformanceIndexes < ActiveRecord::Migration[8.1]
  def change
    add_index :tasks, [ :status, :assignee_id ], name: "index_tasks_on_status_and_assignee_id"
    add_index :tasks, [ :assignee_id, :status ], name: "index_tasks_on_assignee_id_and_status"
    add_index :tasks, [ :creator_id, :status ], name: "index_tasks_on_creator_id_and_status"
    add_index :tasks, [ :status, :due_date ], name: "index_tasks_on_status_and_due_date"
    add_index :tasks, [ :priority, :status ], name: "index_tasks_on_priority_and_status"
    add_index :comments, :created_at, name: "index_comments_on_created_at"
    add_index :comments, [ :task_id, :created_at ], name: "index_comments_on_task_id_and_created_at"
  end
end
