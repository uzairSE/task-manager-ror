# frozen_string_literal: true

class AddForeignKeysToTasks < ActiveRecord::Migration[8.1]
  def change
    # Add foreign keys
    add_reference :tasks, :creator, null: false, foreign_key: { to_table: :users }, index: true
    add_reference :tasks, :assignee, null: true, foreign_key: { to_table: :users }, index: true

    # Add indexes for frequently queried fields
    add_index :tasks, :status
    add_index :tasks, :priority
    add_index :tasks, :due_date

    # Add null constraint on title (if not already present)
    change_column_null :tasks, :title, false
  end
end
