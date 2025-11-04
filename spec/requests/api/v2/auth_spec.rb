# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V2::Auth', type: :request do
  describe 'POST /api/v2/auth/login' do
    let(:user) { create(:user, password: 'password123') }

    it 'returns user and token on successful login' do
      post '/api/v2/auth/login', params: { email: user.email, password: 'password123' }

      expect(response).to have_http_status(:ok)
      expect(json_response['data']).to include('user', 'token')
      expect(json_response['data']['token']).to be_present
    end

    it 'returns error on invalid credentials' do
      post '/api/v2/auth/login', params: { email: user.email, password: 'wrong' }

      expect(response).to have_http_status(:unauthorized)
      expect(json_response['error']['code']).to eq('INVALID_CREDENTIALS')
    end

    it 'handles case-insensitive email' do
      post '/api/v2/auth/login', params: { email: user.email.upcase, password: 'password123' }

      expect(response).to have_http_status(:ok)
    end

    it 'generates token if user does not have one' do
      user.update_column(:authentication_token, nil)
      post '/api/v2/auth/login', params: { email: user.email, password: 'password123' }

      expect(response).to have_http_status(:ok)
      expect(json_response['data']['token']).to be_present
      expect(user.reload.authentication_token).to eq(json_response['data']['token'])
    end
  end

  describe 'POST /api/v2/auth/logout' do
    let(:user) { create(:user).tap { |u| u.generate_authentication_token! } }
    let(:auth_headers) { { 'Authorization' => "Bearer #{user.authentication_token}" } }

    it 'returns success message' do
      post '/api/v2/auth/logout', headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(json_response['message']).to eq('Logged out successfully')
    end

    it 'does not require authentication token to be invalidated' do
      token_before = user.authentication_token
      post '/api/v2/auth/logout', headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(user.reload.authentication_token).to eq(token_before)
    end
  end

  describe 'POST /api/v2/auth/signup' do
    it 'creates a new user with member role' do
      post '/api/v2/auth/signup', params: {
        email: 'new@example.com',
        password: 'password123',
        password_confirmation: 'password123',
        first_name: 'John',
        last_name: 'Doe'
      }

      expect(response).to have_http_status(:created)
      expect(json_response['data']).to include('user', 'token')
      expect(json_response['data']['token']).to be_present

      created_user = User.find_by(email: 'new@example.com')
      expect(created_user).to be_present
      expect(created_user.role).to eq('member')
      expect(created_user.authentication_token).to eq(json_response['data']['token'])
    end

    it 'does not allow role assignment during signup' do
      post '/api/v2/auth/signup', params: {
        email: 'new@example.com',
        password: 'password123',
        password_confirmation: 'password123',
        first_name: 'John',
        last_name: 'Doe',
        role: 'admin'
      }

      expect(response).to have_http_status(:created)
      created_user = User.find_by(email: 'new@example.com')
      expect(created_user.role).to eq('member') # Should default to member, not admin
    end

    it 'returns validation errors for invalid data' do
      post '/api/v2/auth/signup', params: {
        email: 'invalid',
        password: 'short',
        password_confirmation: 'different'
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(json_response['error']['code']).to eq('VALIDATION_ERROR')
    end
  end
end
