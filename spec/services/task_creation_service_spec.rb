# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaskCreationService do
  let(:user) { create(:user) }
  let(:assignee) { create(:user) }
  let(:task_params) do
    {
      title: 'Test Task',
      description: 'Test Description',
      priority: :medium,
      assignee_id: assignee.id
    }
  end

  describe '.call' do
    context 'with valid parameters' do
      it 'creates a task successfully' do
        result = described_class.call(user: user, params: task_params)

        aggregate_failures do
          expect(result).to be_success
          expect(result.data).to be_a(Task)
          expect(result.data.title).to eq('Test Task')
          expect(result.data.status).to eq('pending')
          expect(result.data.creator).to eq(user)
        end
      end

      it 'enqueues notification job when assignee is present' do
        Sidekiq::Testing.fake! do
          Sidekiq::Worker.clear_all
          result = described_class.call(user: user, params: task_params)
          expect(result).to be_success
          expect(TaskNotificationJob.jobs.size).to eq(1)
          expect(TaskNotificationJob.jobs.first['args']).to include(result.data.id)
        end
      end

      it 'does not enqueue notification job when assignee is not present' do
        params_without_assignee = task_params.except(:assignee_id)

        Sidekiq::Testing.fake! do
          Sidekiq::Worker.clear_all
          described_class.call(user: user, params: params_without_assignee)
          expect(TaskNotificationJob.jobs).to be_empty
        end
      end
    end

    context 'with invalid parameters' do
      it 'returns failure with errors' do
        invalid_params = task_params.merge(title: nil)
        result = described_class.call(user: user, params: invalid_params)

        aggregate_failures do
          expect(result).to be_failure
          expect(result.errors).to be_present
        end
      end
    end
  end
end
