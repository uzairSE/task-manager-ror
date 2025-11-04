# frozen_string_literal: true

class TaskPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def dashboard?
    user.present?
  end

  def show?
    user.present? && (admin? || manager? || owns_task? || assigned_to_task?)
  end

  def create?
    user.present?
  end

  def update?
    return false unless user.present?

    admin? || (manager? && !record.archived?) || owns_task?
  end

  def destroy?
    return false unless user.present?

    admin?
  end

  def assign?
    return false unless user.present?

    admin? || manager?
  end

  def complete?
    return false unless user.present?

    admin? || manager? || owns_task? || assigned_to_task?
  end

  def export?
    return false unless user.present?

    admin? || manager? || owns_task? || assigned_to_task?
  end

  def overdue?
    user.present?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user.present?

      if user.admin? || user.manager?
        scope.all
      else
        scope.where(creator_id: user.id).or(scope.where(assignee_id: user.id))
      end
    end
  end

  private

  def admin?
    user&.admin?
  end

  def manager?
    user&.manager?
  end

  def owns_task?
    record.creator_id == user.id
  end

  def assigned_to_task?
    record.assignee_id == user.id
  end
end
