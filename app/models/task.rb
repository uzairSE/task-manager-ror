# frozen_string_literal: true

class Task < ApplicationRecord
  # Enums
  enum status: { pending: 0, in_progress: 1, completed: 2, archived: 3 }
  enum priority: { low: 0, medium: 1, high: 2, urgent: 3 }

  # Associations
  belongs_to :creator, class_name: "User", foreign_key: "creator_id"
  belongs_to :assignee, class_name: "User", foreign_key: "assignee_id", optional: true
  has_many :comments, dependent: :destroy

  # Callbacks for Redis counters
  after_create :increment_creator_tasks_count, :increment_assignee_tasks_count
  after_destroy :decrement_creator_tasks_count, :decrement_assignee_tasks_count

  after_update :handle_assignee_change, if: :saved_change_to_assignee_id?

  # Validations
  validates :title, presence: true
  validates :status, presence: true
  validates :priority, presence: true

  # Scopes
  scope :by_status, ->(status) { where(status: status) if status.present? }
  scope :by_priority, ->(priority) { where(priority: priority) if priority.present? }
  scope :overdue, -> { where("due_date < ?", Time.current).where.not(status: [ :completed, :archived ]) }
  scope :upcoming, ->(days = 7) { where("due_date BETWEEN ? AND ?", Time.current, days.days.from_now) }
  scope :completed_between, ->(start_date, end_date) { completed.where(completed_at: start_date..end_date) }
  scope :assigned_to, ->(user) { user.present? ? where(assignee_id: user.id) : none }
  scope :created_by, ->(user) { user.present? ? where(creator_id: user.id) : none }
  scope :recent, -> { order(created_at: :desc) }
  scope :high_priority, -> { where(priority: [ :high, :urgent ]) }
  scope :completed, -> { where(status: :completed) }

  # Callbacks
  before_validation :set_default_status, on: :create

  private

  def set_default_status
    self.status ||= :pending
  end

  def increment_creator_tasks_count
    User.increment_created_tasks_for(creator_id) if creator_id
  end

  def increment_assignee_tasks_count
    User.increment_assigned_tasks_for(assignee_id) if assignee_id
  end

  def decrement_creator_tasks_count
    User.decrement_created_tasks_for(creator_id) if creator_id
  end

  def decrement_assignee_tasks_count
    User.decrement_assigned_tasks_for(assignee_id) if assignee_id
  end

  def handle_assignee_change
    old_assignee_id, new_assignee_id = saved_change_to_assignee_id

    # Decrement old assignee if exists
    User.decrement_assigned_tasks_for(old_assignee_id) if old_assignee_id.present?

    # Increment new assignee if exists
    User.increment_assigned_tasks_for(new_assignee_id) if new_assignee_id.present?
  end
end
