# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Users', type: :request do
  let(:admin) { create(:user, :admin).tap { |u| u.generate_authentication_token! } }
  let(:manager) { create(:user, :manager).tap { |u| u.generate_authentication_token! } }
  let(:member) { create(:user, :member).tap { |u| u.generate_authentication_token! } }
  let(:admin_headers) { { 'Authorization' => "Bearer #{admin.authentication_token}" } }
  let(:manager_headers) { { 'Authorization' => "Bearer #{manager.authentication_token}" } }
  let(:member_headers) { { 'Authorization' => "Bearer #{member.authentication_token}" } }

  describe 'GET /api/v1/users' do
    let!(:user1) { create(:user, :member) }
    let!(:user2) { create(:user, :manager) }

    it 'allows admin to list users' do
      get '/api/v1/users', headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(json_response['data']).to be_an(Array)
    end

    it 'allows manager to list users' do
      get '/api/v1/users', headers: manager_headers

      expect(response).to have_http_status(:ok)
    end

    it 'denies member from listing users' do
      get '/api/v1/users', headers: member_headers

      expect(response).to have_http_status(:forbidden)
    end

    it 'filters by role' do
      get '/api/v1/users', params: { role: 'member' }, headers: admin_headers

      expect(response).to have_http_status(:ok)
      members = json_response['data']
      expect(members.all? { |u| u['attributes']['role'] == 'member' }).to be true
    end
  end

  describe 'GET /api/v1/users/:id' do
    it 'allows user to view own profile' do
      get "/api/v1/users/#{member.id}", headers: member_headers

      expect(response).to have_http_status(:ok)
      expect(json_response['data']['id']).to eq(member.id.to_s)
    end

    it 'allows admin to view any user' do
      get "/api/v1/users/#{member.id}", headers: admin_headers

      expect(response).to have_http_status(:ok)
    end

    it 'allows manager to view any user' do
      get "/api/v1/users/#{member.id}", headers: manager_headers

      expect(response).to have_http_status(:ok)
    end

    it 'denies member from viewing other member profile' do
      other_member = create(:user, :member)
      get "/api/v1/users/#{other_member.id}", headers: member_headers

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'PATCH /api/v1/users/:id' do
    it 'allows admin to update user role' do
      patch "/api/v1/users/#{member.id}", params: {
        role: 'manager'
      }, headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(member.reload.role).to eq('manager')
    end

    it 'allows user to update own profile' do
      patch "/api/v1/users/#{member.id}", params: {
        first_name: 'Updated Name'
      }, headers: member_headers

      expect(response).to have_http_status(:ok)
      expect(member.reload.first_name).to eq('Updated Name')
    end

    it 'denies member from updating role' do
      patch "/api/v1/users/#{member.id}", params: {
        role: 'admin'
      }, headers: member_headers

      expect(response).to have_http_status(:ok)
      # Role should not change
      expect(member.reload.role).to eq('member')
    end
  end

  describe 'DELETE /api/v1/users/:id' do
    let!(:user_to_delete) { create(:user, :member) }

    it 'allows admin to delete user' do
      delete "/api/v1/users/#{user_to_delete.id}", headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(User.find_by(id: user_to_delete.id)).to be_nil
    end

    it 'denies manager from deleting user' do
      delete "/api/v1/users/#{user_to_delete.id}", headers: manager_headers

      expect(response).to have_http_status(:forbidden)
    end

    it 'denies member from deleting user' do
      delete "/api/v1/users/#{user_to_delete.id}", headers: member_headers

      expect(response).to have_http_status(:forbidden)
    end
  end
end
