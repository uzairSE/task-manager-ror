# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  def index?
    admin? || manager?
  end

  def show?
    admin? || manager? || user_self?
  end

  def create?
    admin?
  end

  def update?
    admin? || user_self?
  end

  def destroy?
    admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user.present?

      if user.admin? || user.manager?
        scope.all
      else
        scope.where(id: user.id)
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

  def user_self?
    record.id == user.id
  end
end
