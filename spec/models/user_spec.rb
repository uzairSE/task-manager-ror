# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:created_tasks).dependent(:destroy) }
    it { should have_many(:assigned_tasks).dependent(:nullify) }
    it { should have_many(:comments).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:role) }

    it 'validates email format' do
      user = build(:user, email: 'invalid-email')
      expect(user).not_to be_valid
      expect(user.errors[:email]).to be_present
    end

    it 'validates valid email format' do
      user = build(:user, email: 'valid@example.com')
      expect(user).to be_valid
    end
  end

  describe 'enums' do
    it { should define_enum_for(:role).with_values(admin: 0, manager: 1, member: 2) }
  end

  describe '#generate_authentication_token!' do
    it 'generates authentication token' do
      user = create(:user)
      token = user.generate_authentication_token!
      expect(token).to be_present
      expect(user.authentication_token).to eq(token)
    end

    it 'generates unique authentication tokens' do
      user1 = create(:user)
      user2 = create(:user)
      user1.generate_authentication_token!
      user2.generate_authentication_token!
      expect(user1.authentication_token).not_to eq(user2.authentication_token)
    end
  end

  describe '#full_name' do
    it 'returns full name' do
      user = create(:user, first_name: 'John', last_name: 'Doe')
      expect(user.full_name).to eq('John Doe')
    end

    it 'handles missing first or last name' do
      user = create(:user, first_name: 'John', last_name: nil)
      expect(user.full_name).to eq('John')
    end
  end
end
