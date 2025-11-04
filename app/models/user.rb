# frozen_string_literal: true

class User < ApplicationRecord
  include RedisCounter

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Enums
  enum role: { admin: 0, manager: 1, member: 2 }

  # Redis counters
  redis_counter :created_tasks
  redis_counter :assigned_tasks

  # Initialize Redis counters from database on first access if Redis is empty
  after_find :initialize_counters, if: -> { Rails.env.development? || Rails.env.test? }

  # Associations
  has_many :created_tasks, class_name: "Task", foreign_key: "creator_id", dependent: :destroy
  has_many :assigned_tasks, class_name: "Task", foreign_key: "assignee_id", dependent: :nullify
  has_many :comments, dependent: :destroy

  # Validations
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, presence: true

  # Callbacks
  before_create :generate_authentication_token

  # Methods
  def full_name
    "#{first_name} #{last_name}".strip
  end

  private

  def generate_authentication_token
    loop do
      self.authentication_token = SecureRandom.hex(32)
      break unless User.exists?(authentication_token: authentication_token)
    end
  end

  def initialize_counters
    # Initialize Redis counters from database if they don't exist
    # This ensures counters are available even if Redis was cleared
    begin
      if created_tasks_count.zero? && created_tasks.exists?
        self.created_tasks_count = created_tasks.count
      end

      if assigned_tasks_count.zero? && assigned_tasks.exists?
        self.assigned_tasks_count = assigned_tasks.count
      end
    rescue Redis::BaseError => e
      Rails.logger.warn "Could not initialize Redis counters: #{e.message}"
    end
  end
end
