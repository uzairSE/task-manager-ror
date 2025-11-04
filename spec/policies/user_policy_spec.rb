# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserPolicy, type: :policy do
  subject { described_class }

  let(:admin) { create(:user, :admin) }
  let(:manager) { create(:user, :manager) }
  let(:member) { create(:user, :member) }
  let(:other_member) { create(:user, :member) }

  permissions :index? do
    it 'allows admin to list users' do
      expect(subject).to permit(admin, User)
    end

    it 'allows manager to list users' do
      expect(subject).to permit(manager, User)
    end

    it 'denies member from listing users' do
      expect(subject).not_to permit(member, User)
    end
  end

  permissions :show? do
    it 'allows admin to view any user' do
      expect(subject).to permit(admin, member)
    end

    it 'allows manager to view any user' do
      expect(subject).to permit(manager, member)
    end

    it 'allows user to view own profile' do
      expect(subject).to permit(member, member)
    end

    it 'denies member from viewing other member\'s profile' do
      expect(subject).not_to permit(member, other_member)
    end
  end

  permissions :create? do
    it 'allows admin to create users' do
      expect(subject).to permit(admin, User)
    end

    it 'denies manager from creating users' do
      expect(subject).not_to permit(manager, User)
    end

    it 'denies member from creating users' do
      expect(subject).not_to permit(member, User)
    end
  end

  permissions :update? do
    it 'allows admin to update any user' do
      expect(subject).to permit(admin, member)
    end

    it 'allows user to update own profile' do
      expect(subject).to permit(member, member)
    end

    it 'denies member from updating other member\'s profile' do
      expect(subject).not_to permit(member, other_member)
    end
  end

  permissions :destroy? do
    it 'allows admin to delete any user' do
      expect(subject).to permit(admin, member)
    end

    it 'denies manager from deleting users' do
      expect(subject).not_to permit(manager, member)
    end

    it 'denies member from deleting users' do
      expect(subject).not_to permit(member, other_member)
    end
  end

  describe 'UserPolicy::Scope' do
    let(:admin) { create(:user, :admin) }
    let(:manager) { create(:user, :manager) }
    let(:member) { create(:user, :member) }
    let(:other_member) { create(:user, :member) }

    it 'admin can see all users' do
      scope = UserPolicy::Scope.new(admin, User).resolve
      expect(scope).to include(admin, manager, member, other_member)
    end

    it 'manager can see all users' do
      scope = UserPolicy::Scope.new(manager, User).resolve
      expect(scope).to include(admin, manager, member, other_member)
    end

    it 'member can only see own profile' do
      scope = UserPolicy::Scope.new(member, User).resolve
      expect(scope).to include(member)
      expect(scope).not_to include(admin, manager, other_member)
    end

    it 'returns empty scope for nil user' do
      scope = UserPolicy::Scope.new(nil, User).resolve
      expect(scope).to be_empty
    end
  end
end
