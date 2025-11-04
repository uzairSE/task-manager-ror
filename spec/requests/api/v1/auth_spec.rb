# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Auth', type: :request do
  describe 'POST /api/v1/auth/login' do
    let(:user) { create(:user, password: 'password123') }

    context 'with valid credentials' do
      it 'returns authentication token' do
        post '/api/v1/auth/login', params: { email: user.email, password: 'password123' }

        expect(response).to have_http_status(:ok)
        expect(json_response['data']).to include('user', 'token')
        expect(json_response['data']['token']).to be_present
      end

      it 'generates token if user does not have one' do
        user.update_column(:authentication_token, nil)
        post '/api/v1/auth/login', params: { email: user.email, password: 'password123' }

        expect(response).to have_http_status(:ok)
        expect(json_response['data']['token']).to be_present
        expect(user.reload.authentication_token).to eq(json_response['data']['token'])
      end
    end

    context 'with invalid credentials' do
      it 'returns unauthorized' do
        post '/api/v1/auth/login', params: { email: user.email, password: 'wrong' }

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['error']['code']).to eq('INVALID_CREDENTIALS')
      end
    end
  end

  describe 'POST /api/v1/auth/signup' do
    context 'with valid parameters' do
      it 'creates a new user' do
        post '/api/v1/auth/signup', params: {
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
        expect(created_user.authentication_token).to eq(json_response['data']['token'])
      end
    end

    context 'with invalid parameters' do
      it 'returns validation errors' do
        post '/api/v1/auth/signup', params: { email: 'invalid' }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']['code']).to eq('VALIDATION_ERROR')
      end
    end
  end

  def json_response
    JSON.parse(response.body)
  end
end
