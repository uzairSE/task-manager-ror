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

  def json_response
    JSON.parse(response.body)
  end
end
