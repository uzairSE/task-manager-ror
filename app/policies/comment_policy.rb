# frozen_string_literal: true

class CommentPolicy < ApplicationPolicy
  def create?
    user.present?
  end

  def destroy?
    return false unless user.present?

    admin? || user_owns_comment?
  end

  private

  def admin?
    user&.admin?
  end

  def user_owns_comment?
    record.user_id == user.id
  end
end
