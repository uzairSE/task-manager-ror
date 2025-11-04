# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaskPolicy, type: :policy do
  subject { described_class }

  let(:admin) { create(:user, :admin) }
  let(:manager) { create(:user, :manager) }
  let(:member) { create(:user, :member) }
  let(:other_member) { create(:user, :member) }
  let(:task) { create(:task, creator: member, assignee: member) }

  permissions :index? do
    it 'allows authenticated users' do
      expect(subject).to permit(admin, Task)
      expect(subject).to permit(manager, Task)
      expect(subject).to permit(member, Task)
    end

    it 'denies unauthenticated users' do
      expect(subject).not_to permit(nil, Task)
    end
  end

  permissions :show? do
    it 'allows admin to view any task' do
      expect(subject).to permit(admin, task)
    end

    it 'allows manager to view any task' do
      expect(subject).to permit(manager, task)
    end

    it 'allows creator to view own task' do
      expect(subject).to permit(member, task)
    end

    it 'allows assignee to view assigned task' do
      assigned_task = create(:task, assignee: member)
      expect(subject).to permit(member, assigned_task)
    end

    it 'denies member from viewing other member\'s task' do
      other_task = create(:task, creator: other_member)
      expect(subject).not_to permit(member, other_task)
    end
  end

  permissions :create? do
    it 'allows authenticated users' do
      expect(subject).to permit(admin, Task)
      expect(subject).to permit(manager, Task)
      expect(subject).to permit(member, Task)
    end
  end

  permissions :update? do
    it 'allows admin to update any task' do
      expect(subject).to permit(admin, task)
    end

    it 'allows manager to update non-archived tasks' do
      expect(subject).to permit(manager, task)
    end

    it 'denies manager from updating archived tasks' do
      archived_task = create(:task, status: :archived)
      expect(subject).not_to permit(manager, archived_task)
    end

    it 'allows creator to update own task' do
      expect(subject).to permit(member, task)
    end

    it 'denies member from updating other member\'s task' do
      other_task = create(:task, creator: other_member)
      expect(subject).not_to permit(member, other_task)
    end
  end

  permissions :destroy? do
    it 'allows admin to delete any task' do
      expect(subject).to permit(admin, task)
    end

    it 'denies manager from deleting tasks' do
      expect(subject).not_to permit(manager, task)
    end

    it 'denies member from deleting tasks' do
      expect(subject).not_to permit(member, task)
    end
  end

  permissions :assign? do
    it 'allows admin to assign tasks' do
      expect(subject).to permit(admin, task)
    end

    it 'allows manager to assign tasks' do
      expect(subject).to permit(manager, task)
    end

    it 'denies member from assigning tasks' do
      expect(subject).not_to permit(member, task)
    end
  end

  permissions :complete? do
    it 'allows admin to complete any task' do
      expect(subject).to permit(admin, task)
    end

    it 'allows manager to complete any task' do
      expect(subject).to permit(manager, task)
    end

    it 'allows creator to complete own task' do
      expect(subject).to permit(member, task)
    end

    it 'allows assignee to complete assigned task' do
      assigned_task = create(:task, assignee: member)
      expect(subject).to permit(member, assigned_task)
    end

    it 'denies member from completing other member\'s task' do
      other_task = create(:task, creator: other_member)
      expect(subject).not_to permit(member, other_task)
    end
  end

  describe 'TaskPolicy::Scope' do
    let(:admin) { create(:user, :admin) }
    let(:manager) { create(:user, :manager) }
    let(:member) { create(:user, :member) }
    let(:other_member) { create(:user, :member) }

    let!(:admin_task) { create(:task, creator: admin) }
    let!(:manager_task) { create(:task, creator: manager) }
    let!(:member_task) { create(:task, creator: member) }
    let!(:other_task) { create(:task, creator: other_member) }
    let!(:assigned_task) { create(:task, assignee: member) }

    it 'admin can see all tasks' do
      scope = TaskPolicy::Scope.new(admin, Task).resolve
      expect(scope).to include(admin_task, manager_task, member_task, other_task, assigned_task)
    end

    it 'manager can see all tasks' do
      scope = TaskPolicy::Scope.new(manager, Task).resolve
      expect(scope).to include(admin_task, manager_task, member_task, other_task, assigned_task)
    end

    it 'member can only see own tasks and assigned tasks' do
      scope = TaskPolicy::Scope.new(member, Task).resolve
      expect(scope).to include(member_task, assigned_task)
      expect(scope).not_to include(admin_task, manager_task, other_task)
    end

    it 'returns empty scope for nil user' do
      scope = TaskPolicy::Scope.new(nil, Task).resolve
      expect(scope).to be_empty
    end
  end
end
