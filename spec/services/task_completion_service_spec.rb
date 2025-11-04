# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TaskCompletionService do
  let(:creator) { create(:user) }
  let(:user) { create(:user) }
  let(:task) { create(:task, creator: creator, status: :pending) }

  describe '.call' do
    context 'with valid task' do
      it 'marks task as completed' do
        result = described_class.call(task: task, user: user)

        aggregate_failures do
          expect(result).to be_success
          expect(result.data.status).to eq('completed')
          expect(result.data.completed_at).to be_present
        end
      end

      it 'sets completed_at timestamp' do
        freeze_time = Time.current
        travel_to(freeze_time) do
          result = described_class.call(task: task, user: user)
          expect(result.data.completed_at).to be_within(1.second).of(freeze_time)
        end
      end

      it 'triggers notification to creator if different from current user' do
        Sidekiq::Testing.fake! do
          Sidekiq::Worker.clear_all
          result = described_class.call(task: task, user: user)
          expect(result).to be_success
          expect(TaskNotificationJob.jobs.size).to eq(1)
          expect(TaskNotificationJob.jobs.first['args']).to eq([ task.id, 'completion' ])
        end
      end

      it 'does not trigger notification if creator is current user' do
        Sidekiq::Testing.fake! do
          Sidekiq::Worker.clear_all
          described_class.call(task: task, user: creator)
          expect(TaskNotificationJob.jobs).to be_empty
        end
      end
    end

    context 'with already completed task' do
      let(:completed_task) { create(:task, status: :completed) }

      it 'returns failure' do
        result = described_class.call(task: completed_task, user: user)

        aggregate_failures do
          expect(result).to be_failure
          expect(result.errors).to include('Task is already completed')
        end
      end
    end
  end
end
