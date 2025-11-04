# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum role: { admin: 0, manager: 1, member: 2 }

  has_many :created_tasks, class_name: "Task", foreign_key: "creator_id", dependent: :destroy
  has_many :assigned_tasks, class_name: "Task", foreign_key: "assignee_id", dependent: :nullify
  has_many :comments, dependent: :destroy

  before_validation :normalize_email

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, presence: true

  def generate_authentication_token!
    loop do
      self.authentication_token = SecureRandom.hex(32)
      break unless User.exists?(authentication_token: authentication_token)
    end
    save!
    authentication_token
  end

  def regenerate_authentication_token!
    generate_authentication_token!
  end

  def invalidate_authentication_token!
    update_column(:authentication_token, nil)
  end

  private

  def normalize_email
    self.email = email&.downcase&.strip
  end
end
