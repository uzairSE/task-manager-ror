# frozen_string_literal: true

class Task < ApplicationRecord
  enum :status, { pending: 0, in_progress: 1, completed: 2, archived: 3 }
  enum :priority, { low: 0, medium: 1, high: 2, urgent: 3 }

  belongs_to :creator, class_name: "User", foreign_key: "creator_id", counter_cache: :created_tasks_count
  belongs_to :assignee, class_name: "User", foreign_key: "assignee_id", optional: true, counter_cache: :assigned_tasks_count
  has_many :comments, dependent: :destroy

  validates :title, presence: true
  validates :status, presence: true
  validates :priority, presence: true

  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :by_priority, ->(priority) { where(priority: priority) if priority.present? }
  scope :overdue, -> { where.not(status: [ :completed, :archived ]).where("due_date < ?", Time.current) }
  scope :upcoming, ->(days = 7) { where("due_date BETWEEN ? AND ?", Time.current, days.days.from_now) }
  scope :completed_between, ->(start_date, end_date) { completed.where(completed_at: start_date..end_date) }
  scope :assigned_to, ->(user) { user.present? ? where(assignee_id: user.id) : none }
  scope :created_by, ->(user) { user.present? ? where(creator_id: user.id) : none }
  scope :recent, -> { order(created_at: :desc) }
  scope :high_priority, -> { where(priority: [ :high, :urgent ]) }
end
