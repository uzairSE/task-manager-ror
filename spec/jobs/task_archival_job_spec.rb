# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaskArchivalJob, type: :job do
  describe '#perform' do
    let!(:old_completed_task) { create(:task, status: :completed, completed_at: 35.days.ago) }
    let!(:recent_completed_task) { create(:task, status: :completed, completed_at: 10.days.ago) }

    it 'archives completed tasks older than 30 days' do
      expect {
        described_class.new.perform
      }.to change { old_completed_task.reload.status }.from('completed').to('archived')
    end

    it 'does not archive recently completed tasks' do
      expect {
        described_class.new.perform
      }.not_to change { recent_completed_task.reload.status }
    end

    it 'uses update_all for batch updates' do
      job = described_class.new
      # Verify that update_all is called (not individual updates)
      expect(Task).not_to receive(:find_each)
      expect_any_instance_of(ActiveRecord::Relation).to receive(:update_all).and_call_original
      job.perform
    end
  end
end
