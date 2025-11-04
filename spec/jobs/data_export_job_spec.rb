# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DataExportJob, type: :job do
  let(:user) { create(:user) }
  let!(:task1) { create(:task, creator: user) }
  let!(:task2) { create(:task, assignee: user) }

  describe '#perform' do
    it 'generates CSV for user tasks' do
      expect {
        described_class.perform_async(user.id)
      }.to change { described_class.jobs.size }.by(1)
    end

    it 'handles non-existent user gracefully' do
      expect {
        described_class.new.perform(999999)
      }.not_to raise_error
    end

    it 'generates CSV with all user tasks' do
      job = described_class.new
      job.perform(user.id)

      # Check that CSV file was created
      csv_files = Dir[Rails.root.join('tmp', "tasks_export_#{user.id}_*.csv")]
      expect(csv_files.size).to eq(1)

      # Verify CSV content
      csv_content = File.read(csv_files.first)
      expect(csv_content).to include('Title')
      expect(csv_content).to include(task1.title)
      expect(csv_content).to include(task2.title)

      # Cleanup
      csv_files.each { |f| File.delete(f) }
    end
  end
end
