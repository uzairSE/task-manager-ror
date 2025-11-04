class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.text :description
      t.integer :status, default: 0, null: false, index: true # 0: pending, 1: in_progress, 2: completed, 3: archived
      t.integer :priority, default: 1, null: false, index: true # 0: low, 1: medium, 2: high, 3: urgent
      t.datetime :due_date, index: true
      t.datetime :completed_at, index: true
      t.references :creator, null: false, foreign_key: { to_table: :users }, index: true
      t.references :assignee, null: true, foreign_key: { to_table: :users }, index: true

      t.timestamps
    end

    add_index :tasks, :created_at
  end
end
