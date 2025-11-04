# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Task, type: :model do
  describe 'associations' do
    it { should belong_to(:creator).class_name('User') }
    it { should belong_to(:assignee).class_name('User').optional }
    it { should have_many(:comments).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:priority) }
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(pending: 0, in_progress: 1, completed: 2, archived: 3) }
    it { should define_enum_for(:priority).with_values(low: 0, medium: 1, high: 2, urgent: 3) }

    describe 'status enum methods' do
      it 'has pending? method' do
        task = create(:task, status: :pending)
        expect(task.pending?).to be true
      end

      it 'has in_progress? method' do
        task = create(:task, status: :in_progress)
        expect(task.in_progress?).to be true
      end

      it 'has completed? method' do
        task = create(:task, status: :completed)
        expect(task.completed?).to be true
      end

      it 'has archived? method' do
        task = create(:task, status: :archived)
        expect(task.archived?).to be true
      end
    end

    describe 'priority enum methods' do
      it 'has low? method' do
        task = create(:task, priority: :low)
        expect(task.low?).to be true
      end

      it 'has high? method' do
        task = create(:task, priority: :high)
        expect(task.high?).to be true
      end

      it 'has urgent? method' do
        task = create(:task, priority: :urgent)
        expect(task.urgent?).to be true
      end
    end
  end

  describe 'scopes' do
    let!(:pending_task) { create(:task, :pending) }
    let!(:in_progress_task) { create(:task, :in_progress) }
    let!(:completed_task) { create(:task, :completed, completed_at: 5.days.ago) }
    let!(:archived_task) { create(:task, :archived) }
    let!(:low_priority_task) { create(:task, :low_priority) }
    let!(:high_priority_task) { create(:task, :high_priority) }
    let!(:urgent_task) { create(:task, :urgent) }
    let!(:overdue_task) { create(:task, :overdue, due_date: 2.days.ago) }
    let!(:upcoming_task) { create(:task, due_date: 3.days.from_now) }
    let(:user) { create(:user) }
    let!(:user_task) { create(:task, creator: user) }
    let!(:assigned_task) { create(:task, assignee: user) }
    let!(:old_completed_task) { create(:task, :completed, completed_at: 10.days.ago) }
    let!(:recent_task) { create(:task, created_at: 1.hour.ago) }
    let!(:old_task) { create(:task, created_at: 1.week.ago) }

    describe '.by_status' do
      it 'filters tasks by status' do
        expect(described_class.by_status('pending')).to include(pending_task)
        expect(described_class.by_status('pending')).not_to include(in_progress_task)
      end
    end

    describe '.by_priority' do
      it 'filters tasks by priority' do
        expect(described_class.by_priority('low')).to include(low_priority_task)
        expect(described_class.by_priority('low')).not_to include(high_priority_task)
      end
    end

    describe '.overdue' do
      it 'returns tasks past due_date that are not completed or archived' do
        overdue_tasks = described_class.overdue
        expect(overdue_tasks).to include(overdue_task)
        expect(overdue_tasks).not_to include(completed_task)
        expect(overdue_tasks).not_to include(archived_task)
      end
    end

    describe '.upcoming' do
      it 'returns tasks due within specified days (default 7)' do
        upcoming_tasks = described_class.upcoming
        expect(upcoming_tasks).to include(upcoming_task)
        expect(upcoming_tasks).not_to include(overdue_task)
      end

      it 'accepts custom days parameter' do
        task_due_in_10_days = create(:task, due_date: 10.days.from_now)
        upcoming_tasks = described_class.upcoming(5)
        expect(upcoming_tasks).not_to include(task_due_in_10_days)
      end
    end

    describe '.completed_between' do
      it 'returns completed tasks within date range' do
        start_date = 12.days.ago
        end_date = 8.days.ago
        range_tasks = described_class.completed_between(start_date, end_date)
        expect(range_tasks).to include(old_completed_task)
        expect(range_tasks).not_to include(completed_task)
      end
    end

    describe '.assigned_to' do
      it 'returns tasks assigned to specific user' do
        assigned_tasks = described_class.assigned_to(user)
        expect(assigned_tasks).to include(assigned_task)
        expect(assigned_tasks).not_to include(user_task)
      end
    end

    describe '.created_by' do
      it 'returns tasks created by specific user' do
        created_tasks = described_class.created_by(user)
        expect(created_tasks).to include(user_task)
        expect(created_tasks).not_to include(assigned_task)
      end
    end

    describe '.recent' do
      it 'orders tasks by created_at descending' do
        recent_tasks = described_class.recent.limit(2)
        expect(recent_tasks.first.created_at).to be > recent_tasks.last.created_at
      end
    end

    describe '.high_priority' do
      it 'returns tasks with high or urgent priority' do
        high_priority_tasks = described_class.high_priority
        expect(high_priority_tasks).to include(high_priority_task)
        expect(high_priority_tasks).to include(urgent_task)
        expect(high_priority_tasks).not_to include(low_priority_task)
      end
    end

    describe '.completed' do
      it 'returns only completed tasks' do
        completed_tasks = described_class.completed
        expect(completed_tasks).to include(completed_task)
        expect(completed_tasks).not_to include(pending_task)
        expect(completed_tasks).not_to include(in_progress_task)
      end
    end
  end

  describe 'defaults' do
    it 'defaults status to pending when not explicitly set' do
      creator = create(:user)
      # Don't set status explicitly - database default should be 0 (pending)
      task = Task.new(title: 'Test', priority: :medium, creator: creator)
      # Status should be set by database default (0 = pending)
      expect(task.save).to be true
      expect(task.id).to be_present
      task.reload
      expect(task.status).to eq('pending')
    end

    it 'preserves explicitly set status' do
        task = build(:task, status: :in_progress)
        task.valid?
        expect(task.status).to eq('in_progress')
    end
  end

  describe 'counter cache' do
    let(:user) { create(:user) }

    it 'updates creator created_tasks_count when task is created' do
      expect {
        create(:task, creator: user)
      }.to change { user.reload.created_tasks_count }.by(1)
    end

    it 'updates assignee assigned_tasks_count when task is assigned' do
      task = create(:task, :without_assignee, creator: user)
      expect {
        task.update(assignee: user)
      }.to change { user.reload.assigned_tasks_count }.by(1)
    end

    it 'decrements counts when task is destroyed' do
      task = create(:task, creator: user, assignee: user)
      expect {
        task.destroy
      }.to change { user.reload.created_tasks_count }.by(-1)
        .and change { user.reload.assigned_tasks_count }.by(-1)
    end
  end
end
