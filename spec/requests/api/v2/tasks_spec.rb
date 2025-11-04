# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V2::Tasks', type: :request do
  let(:admin) { create(:user, :admin).tap { |u| u.generate_authentication_token! } }
  let(:member) { create(:user, :member) }
  let(:auth_headers) { { 'Authorization' => "Bearer #{admin.authentication_token}" } }

  describe 'GET /api/v2/tasks' do
    let!(:task1) { create(:task, creator: admin) }
    let!(:task2) { create(:task, creator: member) }

    it 'requires authentication' do
      get '/api/v2/tasks'
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns tasks for authenticated user' do
      get '/api/v2/tasks', headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(json_response['data']).to be_an(Array)
    end

    it 'filters by status' do
      create(:task, status: :completed, creator: admin)
      get '/api/v2/tasks', params: { status: 'pending' }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      pending_tasks = json_response['data']
      expect(pending_tasks.all? { |t| t['attributes']['status'] == 'pending' }).to be true
    end

    it 'filters by priority' do
      create(:task, priority: :high, creator: admin)
      get '/api/v2/tasks', params: { priority: 'high' }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      high_priority_tasks = json_response['data']
      expect(high_priority_tasks.all? { |t| t['attributes']['priority'] == 'high' }).to be true
    end
  end

  describe 'GET /api/v2/tasks/:id' do
    let(:task) { create(:task, creator: admin, assignee: member) }

    it 'returns task details' do
      get "/api/v2/tasks/#{task.id}", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(json_response['data']['id']).to eq(task.id.to_s)
    end

    it 'returns 404 for non-existent task' do
      get '/api/v2/tasks/999999', headers: auth_headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v2/tasks' do
    it 'creates a task' do
      post '/api/v2/tasks', params: {
        title: 'New Task',
        priority: 'medium'
      }, headers: auth_headers

      expect(response).to have_http_status(:created)
      expect(json_response['data']['attributes']['title']).to eq('New Task')
    end

    it 'returns validation errors for invalid data' do
      post '/api/v2/tasks', params: {
        title: ''
      }, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['error']['code']).to eq('VALIDATION_ERROR')
    end
  end

  describe 'GET /api/v2/tasks/dashboard' do
    let!(:tasks) { create_list(:task, 10, creator: admin, assignee: member) }

    it 'returns dashboard data' do
      get '/api/v2/tasks/dashboard', headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(json_response['data']).to include('status_counts', 'overdue_count')
    end

    it 'caches dashboard data' do
      Rails.cache.clear

      # First request
      get '/api/v2/tasks/dashboard', headers: auth_headers
      first_response = json_response['data']

      # Second request should use cache
      get '/api/v2/tasks/dashboard', headers: auth_headers
      second_response = json_response['data']

      expect(first_response['status_counts']).to eq(second_response['status_counts'])
    end
  end
end
