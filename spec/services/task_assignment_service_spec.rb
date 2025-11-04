# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaskAssignmentService do
  let(:admin) { create(:user, :admin) }
  let(:manager) { create(:user, :manager) }
  let(:member) { create(:user, :member) }
  let(:assignee) { create(:user) }
  let(:task) { create(:task, creator: admin) }

  describe '.call' do
    context 'with authorized user' do
      it 'assigns task successfully' do
        result = described_class.call(
          task: task,
          assignee: assignee,
          assigned_by: admin
        )

        aggregate_failures do
          expect(result).to be_success
          expect(result.data.assignee).to eq(assignee)
        end
      end

      it 'allows manager to assign tasks' do
        result = described_class.call(
          task: task,
          assignee: assignee,
          assigned_by: manager
        )

        expect(result).to be_success
      end

      it 'enqueues notification job' do
        Sidekiq::Testing.fake! do
          Sidekiq::Worker.clear_all
          described_class.call(
            task: task,
            assignee: assignee,
            assigned_by: admin
          )
          expect(TaskNotificationJob.jobs.size).to eq(1)
          expect(TaskNotificationJob.jobs.first['args']).to include(task.id)
        end
      end
    end

    context 'with unauthorized user' do
      it 'returns failure for member' do
        result = described_class.call(
          task: task,
          assignee: assignee,
          assigned_by: member
        )

        aggregate_failures do
          expect(result).to be_failure
          expect(result.errors).to include('You are not authorized to assign tasks')
        end
      end
    end

    context 'with invalid assignee' do
      it 'returns failure when assignee is nil' do
        result = described_class.call(
          task: task,
          assignee: nil,
          assigned_by: admin
        )

        expect(result).to be_failure
      end
    end
  end
end
