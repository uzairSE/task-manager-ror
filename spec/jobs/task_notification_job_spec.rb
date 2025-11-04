# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaskNotificationJob, type: :job do
  let(:assignee) { create(:user) }
  let(:creator) { create(:user) }
  let(:task) { create(:task, assignee: assignee, creator: creator) }

  describe '#perform' do
    it 'sends assignment notification for assigned task' do
      job = described_class.new
      expect(Rails.logger).to receive(:info).with(/Sending assignment notification/)
      job.perform(task.id, 'assignment')
    end

    it 'sends completion notification when notification_type is completion' do
      completed_task = create(:task, status: :completed, creator: creator)
      job = described_class.new
      expect(Rails.logger).to receive(:info).with(/Sending completion notification/)
      job.perform(completed_task.id, 'completion')
    end

    it 'handles non-existent task gracefully' do
      job = described_class.new
      expect {
        job.perform(999999)
      }.not_to raise_error
    end

    it 'handles task without assignee for assignment notification' do
      task_without_assignee = create(:task, assignee: nil, creator: creator)
      job = described_class.new
      expect(Rails.logger).not_to receive(:info)
      job.perform(task_without_assignee.id, 'assignment')
    end
  end
end
