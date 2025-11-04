# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Comments', type: :request do
  let(:admin) { create(:user, :admin).tap { |u| u.generate_authentication_token! } }
  let(:member) { create(:user, :member) }
  let(:task) { create(:task, creator: admin, assignee: member) }
  let(:auth_headers) { { 'Authorization' => "Bearer #{admin.authentication_token}" } }

  describe 'GET /api/v1/tasks/:task_id/comments' do
    let!(:comment1) { create(:comment, task: task, user: admin) }
    let!(:comment2) { create(:comment, task: task, user: member) }

    it 'returns comments for a task' do
      get "/api/v1/tasks/#{task.id}/comments", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(json_response['data']).to be_an(Array)
      expect(json_response['data'].length).to eq(2)
    end

    it 'requires authentication' do
      get "/api/v1/tasks/#{task.id}/comments"
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 404 for non-existent task' do
      get '/api/v1/tasks/999999/comments', headers: auth_headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/tasks/:task_id/comments' do
    it 'creates a comment' do
      post "/api/v1/tasks/#{task.id}/comments", params: {
        content: 'This is a comment'
      }, headers: auth_headers

      expect(response).to have_http_status(:created)
      expect(json_response['data']['attributes']['content']).to eq('This is a comment')
    end

    it 'returns validation errors for invalid data' do
      post "/api/v1/tasks/#{task.id}/comments", params: {
        content: ''
      }, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe 'DELETE /api/v1/tasks/:task_id/comments/:id' do
    let!(:comment) { create(:comment, task: task, user: admin) }

    it 'deletes a comment' do
      delete "/api/v1/tasks/#{task.id}/comments/#{comment.id}", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(Comment.find_by(id: comment.id)).to be_nil
    end

    it 'requires authorization' do
      member_token = member.tap { |u| u.generate_authentication_token! }.authentication_token
      member_headers = { 'Authorization' => "Bearer #{member_token}" }

      delete "/api/v1/tasks/#{task.id}/comments/#{comment.id}", headers: member_headers

      expect(response).to have_http_status(:forbidden)
    end
  end
end
