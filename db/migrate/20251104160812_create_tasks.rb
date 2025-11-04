class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.string :title
      t.text :description
      t.integer :status
      t.integer :priority
      t.datetime :due_date
      t.datetime :completed_at

      t.timestamps
    end
  end
end
