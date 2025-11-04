# frozen_string_literal: true

FactoryBot.define do
  factory :task do
    title { Faker::Lorem.sentence(word_count: 3) }
    description { Faker::Lorem.paragraph }
    status { :pending }
    priority { :medium }
    due_date { rand(30.days).seconds.from_now }
    creator { association :user }
    assignee { association :user }

    trait :pending do
      status { :pending }
    end

    trait :in_progress do
      status { :in_progress }
    end

    trait :completed do
      status { :completed }
      completed_at { Time.current }
    end

    trait :archived do
      status { :archived }
      completed_at { 35.days.ago }
    end

    trait :low_priority do
      priority { :low }
    end

    trait :medium_priority do
      priority { :medium }
    end

    trait :high_priority do
      priority { :high }
    end

    trait :urgent do
      priority { :urgent }
    end

    trait :overdue do
      due_date { 1.day.ago }
      status { :pending }
    end

    trait :without_assignee do
      assignee { nil }
    end
  end
end
