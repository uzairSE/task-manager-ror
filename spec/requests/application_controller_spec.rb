# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationController, type: :request do
  describe 'route_not_found' do
    it 'returns 404 for unmatched routes' do
      get '/non-existent-route'

      expect(response).to have_http_status(:not_found)
      expect(json_response['error']['code']).to eq('NOT_FOUND')
      expect(json_response['error']['message']).to eq('Route not found')
    end

    it 'handles POST requests to unmatched routes' do
      post '/non-existent-route'

      expect(response).to have_http_status(:not_found)
    end
  end
end
