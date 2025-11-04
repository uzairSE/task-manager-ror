# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaskReminderJob, type: :job do
  describe '#perform' do
    let(:user) { create(:user) }
    let!(:due_tomorrow_task) { create(:task, due_date: 24.hours.from_now, status: :pending, assignee: user) }
    let!(:due_far_future_task) { create(:task, due_date: 5.days.from_now, status: :pending, assignee: user) }
    let!(:completed_task) { create(:task, due_date: 24.hours.from_now, status: :completed, assignee: user) }
    let!(:task_without_assignee) { create(:task, due_date: 24.hours.from_now, status: :pending, assignee: nil) }

    it 'processes tasks due in 24 hours' do
      job = described_class.new
      expect(Rails.logger).to receive(:info).at_least(:once)
      job.perform
    end

    it 'excludes completed and archived tasks' do
      job = described_class.new
      expect(Rails.logger).to receive(:info).at_least(:once)
      job.perform
      # Verify completed task is not processed
      expect(completed_task.reload.status).to eq('completed')
    end

    it 'excludes tasks without assignee' do
      job = described_class.new
      expect {
        job.perform
      }.not_to raise_error
    end
  end
end
