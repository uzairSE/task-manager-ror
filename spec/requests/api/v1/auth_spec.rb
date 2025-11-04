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

        expect(response).to have_http_status(:unprocessable_content)
        expect(json_response['error']['code']).to eq('VALIDATION_ERROR')
      end
    end
  end

  describe 'POST /api/v1/auth/password/reset' do
    context 'with existing user' do
      let(:user) { create(:user) }

      it 'sends password reset instructions' do
        # Stub Devise method since routes aren't configured in API
        allow_any_instance_of(User).to receive(:send_reset_password_instructions).and_return(true)

        post '/api/v1/auth/password/reset', params: { email: user.email }

        expect(response).to have_http_status(:ok)
        expect(json_response['message']).to include('instructions sent')
      end
    end

    context 'with non-existent user' do
      it 'returns success message without revealing user existence' do
        post '/api/v1/auth/password/reset', params: { email: 'nonexistent@example.com' }

        expect(response).to have_http_status(:ok)
        expect(json_response['message']).to include('If the email exists')
      end
    end

    context 'with nested params' do
      let(:user) { create(:user) }

      it 'handles nested auth params' do
        # Stub Devise method since routes aren't configured in API
        allow_any_instance_of(User).to receive(:send_reset_password_instructions).and_return(true)

        post '/api/v1/auth/password/reset', params: { auth: { email: user.email } }

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'POST /api/v1/auth/login' do
    context 'with nested params' do
      let(:user) { create(:user, password: 'password123') }

      it 'handles nested auth params' do
        post '/api/v1/auth/login', params: { auth: { email: user.email, password: 'password123' } }

        expect(response).to have_http_status(:ok)
        expect(json_response['data']).to include('user', 'token')
      end
    end
  end

  def json_response
    JSON.parse(response.body)
  end
end
