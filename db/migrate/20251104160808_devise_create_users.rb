# frozen_string_literal: true

class DeviseCreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      ## Database authenticatable
      t.string :email, null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      ## Recoverable
      t.string :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Custom fields
      t.string :first_name
      t.string :last_name
      t.integer :role, default: 2, null: false # 0: admin, 1: manager, 2: member
      t.string :authentication_token
      t.integer :created_tasks_count, default: 0, null: false
      t.integer :assigned_tasks_count, default: 0, null: false

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :authentication_token, unique: true
    add_index :users, :role
  end
end
