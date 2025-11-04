# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Tasks', type: :request do
  let(:admin) { create(:user, :admin).tap { |u| u.generate_authentication_token! } }
  let(:manager) { create(:user, :manager) }
  let(:member) { create(:user, :member) }
  let(:auth_headers) { { 'Authorization' => "Bearer #{admin.authentication_token}" } }

  describe 'GET /api/v1/tasks' do
    let!(:task1) { create(:task, creator: admin) }
    let!(:task2) { create(:task, creator: manager) }

    it 'requires authentication' do
      get '/api/v1/tasks'
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns tasks for authenticated user' do
      get '/api/v1/tasks', headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(json_response['data']).to be_an(Array)
    end

    it 'filters by status' do
      create(:task, status: :completed, creator: admin)
      get '/api/v1/tasks', params: { status: 'pending' }, headers: auth_headers

      tasks = json_response['data']
      expect(tasks.all? { |t| t['attributes']['status'] == 'pending' }).to be true
    end
  end

  describe 'POST /api/v1/tasks' do
    it 'creates a task' do
      post '/api/v1/tasks', params: {
        title: 'New Task',
        description: 'Description',
        priority: 'medium'
      }, headers: auth_headers

      expect(response).to have_http_status(:created)
      expect(json_response['data']['attributes']['title']).to eq('New Task')
    end
  end

  describe 'GET /api/v1/tasks/dashboard' do
    let!(:tasks) { create_list(:task, 20, creator: admin, assignee: member) }

    it 'returns dashboard data without N+1 queries' do
      expect {
        get '/api/v1/tasks/dashboard', headers: auth_headers
      }.not_to exceed_query_limit(15) # Reasonable limit for dashboard queries (includes auth, policy scope, etc.)

      expect(response).to have_http_status(:ok)
      expect(json_response['data']).to include('status_counts', 'overdue_count')
    end

    it 'returns dashboard data within acceptable time' do
      start_time = Time.current
      get '/api/v1/tasks/dashboard', headers: auth_headers
      elapsed_time = Time.current - start_time

      expect(response).to have_http_status(:ok)
      # Should respond within 500ms without cache, < 200ms with cache
      expect(elapsed_time).to be < 0.5
    end

    it 'caches dashboard data for subsequent requests' do
      # Clear cache first
      Rails.cache.clear

      # First request - cache miss
      get '/api/v1/tasks/dashboard', headers: auth_headers
      first_response = json_response['data']

      # Second request - should use cache
      get '/api/v1/tasks/dashboard', headers: auth_headers
      second_response = json_response['data']

      # Data should be identical (cached)
      expect(first_response['status_counts']).to eq(second_response['status_counts'])
      expect(first_response['overdue_count']).to eq(second_response['overdue_count'])
      expect(response).to have_http_status(:ok)
    end

    it 'invalidates cache when task is created' do
      # Clear cache first
      Rails.cache.clear

      # Populate cache
      get '/api/v1/tasks/dashboard', headers: auth_headers
      cached_data = json_response['data']
      cached_pending_count = cached_data['status_counts']['pending'] || 0

      # Create new task
      post '/api/v1/tasks', params: {
        title: 'New Task',
        priority: 'medium'
      }, headers: auth_headers

      # Cache should be invalidated
      get '/api/v1/tasks/dashboard', headers: auth_headers
      new_data = json_response['data']
      new_pending_count = new_data['status_counts']['pending'] || 0

      # Status counts should be different (pending count should increase)
      expect(new_pending_count).to eq(cached_pending_count + 1)
    end

    it 'invalidates cache when task is updated' do
      # Clear cache first
      Rails.cache.clear

      task = create(:task, creator: admin, status: :pending)

      # Populate cache
      get '/api/v1/tasks/dashboard', headers: auth_headers
      cached_data = json_response['data']
      cached_pending = cached_data['status_counts']['pending'] || 0
      cached_completed = cached_data['status_counts']['completed'] || 0

      # Update task status
      patch "/api/v1/tasks/#{task.id}", params: {
        status: 'completed'
      }, headers: auth_headers

      # Cache should be invalidated
      get '/api/v1/tasks/dashboard', headers: auth_headers
      new_data = json_response['data']
      new_pending = new_data['status_counts']['pending'] || 0
      new_completed = new_data['status_counts']['completed'] || 0

      # Status counts should be different
      expect(new_pending).to eq(cached_pending - 1)
      expect(new_completed).to eq(cached_completed + 1)
    end

    it 'invalidates cache when task is deleted' do
      # Clear cache first
      Rails.cache.clear

      task = create(:task, creator: admin, status: :pending)

      # Populate cache
      get '/api/v1/tasks/dashboard', headers: auth_headers
      cached_data = json_response['data']
      cached_pending = cached_data['status_counts']['pending'] || 0
      total_cached = cached_data['status_counts'].values.sum

      # Delete task
      delete "/api/v1/tasks/#{task.id}", headers: auth_headers

      # Cache should be invalidated
      get '/api/v1/tasks/dashboard', headers: auth_headers
      new_data = json_response['data']
      new_pending = new_data['status_counts']['pending'] || 0
      total_new = new_data['status_counts'].values.sum

      # Status counts should be different (total should decrease by 1)
      expect(total_new).to eq(total_cached - 1)
      expect(new_pending).to eq(cached_pending - 1)
    end

    it 'returns correct dashboard structure' do
      get '/api/v1/tasks/dashboard', headers: auth_headers

      expect(response).to have_http_status(:ok)
      data = json_response['data']

      expect(data).to have_key('status_counts')
      expect(data).to have_key('overdue_count')
      expect(data).to have_key('assigned_incomplete_tasks')
      expect(data).to have_key('recent_activity')

      expect(data['status_counts']).to be_a(Hash)
      expect(data['overdue_count']).to be_a(Integer)
      expect(data['assigned_incomplete_tasks']).to have_key('data')
      expect(data['recent_activity']).to have_key('data')
    end
  end

  describe 'POST /api/v1/tasks/:id/assign' do
    let(:task) { create(:task, creator: admin) }
    let(:assignee) { create(:user, :member) }

    it 'assigns task to user' do
      post "/api/v1/tasks/#{task.id}/assign", params: { assignee_id: assignee.id }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(task.reload.assignee).to eq(assignee)
    end

    it 'returns 404 for non-existent assignee' do
      post "/api/v1/tasks/#{task.id}/assign", params: { assignee_id: 999999 }, headers: auth_headers

      expect(response).to have_http_status(:not_found)
      expect(json_response['error']['code']).to eq('NOT_FOUND')
      expect(json_response['error']['message']).to include('Assignee')
    end

    it 'handles assignment service errors' do
      allow(TaskAssignmentService).to receive(:call).and_return(
        double(success?: false, errors: [ "Assignment failed" ])
      )

      post "/api/v1/tasks/#{task.id}/assign", params: { assignee_id: assignee.id }, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['error']['code']).to eq('ASSIGNMENT_ERROR')
    end
  end

  describe 'POST /api/v1/tasks/:id/export' do
    let(:task) { create(:task, creator: admin) }

    it 'queues export job' do
      expect {
        post "/api/v1/tasks/#{task.id}/export", headers: auth_headers
      }.to change { DataExportJob.jobs.size }.by(1)

      expect(response).to have_http_status(:accepted)
      expect(json_response['message']).to include('Export job queued')
    end
  end

  describe 'POST /api/v1/tasks/:id/complete' do
    let(:task) { create(:task, creator: admin, status: :in_progress) }

    it 'completes task successfully' do
      post "/api/v1/tasks/#{task.id}/complete", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(task.reload.status).to eq('completed')
    end

    it 'handles completion service errors' do
      allow(TaskCompletionService).to receive(:call).and_return(
        double(success?: false, errors: [ "Completion failed" ])
      )

      post "/api/v1/tasks/#{task.id}/complete", headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['error']['code']).to eq('COMPLETION_ERROR')
    end
  end

  describe 'GET /api/v1/tasks' do
    it 'filters by assignee_id' do
      assignee = create(:user, :member)
      create(:task, creator: admin, assignee: assignee)
      create(:task, creator: admin, assignee: nil)

      get '/api/v1/tasks', params: { assignee_id: assignee.id }, headers: auth_headers

      tasks = json_response['data']
      expect(tasks.length).to be > 0
      expect(tasks.all? { |t| t['relationships']['assignee']['data'] && t['relationships']['assignee']['data']['id'].to_i == assignee.id }).to be true
    end

    it 'ignores invalid assignee_id' do
      create(:task, creator: admin)
      get '/api/v1/tasks', params: { assignee_id: 999999 }, headers: auth_headers

      tasks = json_response['data']
      expect(tasks.length).to be > 0
    end

    it 'filters by creator_id' do
      creator = create(:user, :manager)
      create(:task, creator: creator)
      create(:task, creator: admin)

      get '/api/v1/tasks', params: { creator_id: creator.id }, headers: auth_headers

      tasks = json_response['data']
      expect(tasks.length).to be > 0
      expect(tasks.all? { |t| t['relationships']['creator']['data']['id'].to_i == creator.id }).to be true
    end

    it 'ignores invalid creator_id' do
      create(:task, creator: admin)
      get '/api/v1/tasks', params: { creator_id: 999999 }, headers: auth_headers

      tasks = json_response['data']
      expect(tasks.length).to be > 0
    end

    it 'filters by priority' do
      create(:task, creator: admin, priority: :high)
      create(:task, creator: admin, priority: :low)

      get '/api/v1/tasks', params: { priority: 'high' }, headers: auth_headers

      tasks = json_response['data']
      expect(tasks.all? { |t| t['attributes']['priority'] == 'high' }).to be true
    end

    it 'sorts by recent' do
      old_task = create(:task, creator: admin, created_at: 2.days.ago)
      new_task = create(:task, creator: admin, created_at: 1.day.ago)

      get '/api/v1/tasks', params: { sort: 'recent' }, headers: auth_headers

      tasks = json_response['data']
      expect(tasks.first['id'].to_i).to eq(new_task.id)
    end

    it 'sorts by oldest' do
      old_task = create(:task, creator: admin, created_at: 2.days.ago)
      new_task = create(:task, creator: admin, created_at: 1.day.ago)

      get '/api/v1/tasks', params: { sort: 'oldest' }, headers: auth_headers

      tasks = json_response['data']
      expect(tasks.first['id'].to_i).to eq(old_task.id)
    end

    it 'sorts by due_date' do
      task1 = create(:task, creator: admin, due_date: 2.days.from_now)
      task2 = create(:task, creator: admin, due_date: 1.day.from_now)

      get '/api/v1/tasks', params: { sort: 'due_date' }, headers: auth_headers

      tasks = json_response['data']
      due_dates = tasks.map { |t| Time.parse(t['attributes']['due_date']) }
      expect(due_dates).to eq(due_dates.sort)
    end

    it 'handles multiple filters combined' do
      assignee = create(:user, :member)
      create(:task, creator: admin, assignee: assignee, status: :pending, priority: :high)
      create(:task, creator: admin, assignee: assignee, status: :completed, priority: :high)
      create(:task, creator: admin, assignee: nil, status: :pending, priority: :high)

      get '/api/v1/tasks', params: {
        assignee_id: assignee.id,
        status: 'pending',
        priority: 'high'
      }, headers: auth_headers

      tasks = json_response['data']
      expect(tasks.length).to eq(1)
      expect(tasks.first['attributes']['status']).to eq('pending')
      expect(tasks.first['attributes']['priority']).to eq('high')
    end
  end

  describe 'GET /api/v1/tasks/overdue' do
    it 'returns overdue tasks' do
      overdue_task = create(:task, creator: admin, due_date: 1.day.ago, status: :pending)
      create(:task, creator: admin, due_date: 1.day.from_now, status: :pending)
      create(:task, creator: admin, due_date: 1.day.ago, status: :completed)

      get '/api/v1/tasks/overdue', headers: auth_headers

      expect(response).to have_http_status(:ok)
      tasks = json_response['data']
      expect(tasks.length).to eq(1)
      expect(tasks.first['id'].to_i).to eq(overdue_task.id)
    end
  end

  describe 'POST /api/v1/tasks' do
    it 'handles task creation service errors' do
      allow(TaskCreationService).to receive(:call).and_return(
        double(success?: false, errors: [ "Creation failed" ])
      )

      post '/api/v1/tasks', params: {
        title: 'New Task',
        priority: 'medium'
      }, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['error']['code']).to eq('VALIDATION_ERROR')
      expect(json_response['error']['message']).to eq('Task creation failed')
    end
  end

  describe 'PATCH /api/v1/tasks/:id' do
    let(:task) { create(:task, creator: admin) }

    it 'updates task successfully' do
      patch "/api/v1/tasks/#{task.id}", params: {
        title: 'Updated Title',
        description: 'Updated Description'
      }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(task.reload.title).to eq('Updated Title')
      expect(task.description).to eq('Updated Description')
    end

    it 'handles validation errors' do
      patch "/api/v1/tasks/#{task.id}", params: {
        title: ''
      }, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['error']['code']).to eq('VALIDATION_ERROR')
    end
  end

  def json_response
    JSON.parse(response.body)
  end
end
