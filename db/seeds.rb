# frozen_string_literal: true

# Clear existing data
User.destroy_all
Task.destroy_all
Comment.destroy_all

# Create users
admin = User.create!(
  email: "admin@example.com",
  password: "password123",
  password_confirmation: "password123",
  first_name: "Admin",
  last_name: "User",
  role: :admin
)

manager = User.create!(
  email: "manager@example.com",
  password: "password123",
  password_confirmation: "password123",
  first_name: "Manager",
  last_name: "User",
  role: :manager
)

member = User.create!(
  email: "member@example.com",
  password: "password123",
  password_confirmation: "password123",
  first_name: "Member",
  last_name: "User",
  role: :member
)

# Create tasks
tasks = []
20.times do |i|
  status = [ :pending, :in_progress, :completed, :archived ].sample
  creator = [ admin, manager, member ].sample
  assignee = [ admin, manager, member, nil ].sample
  completed_at = (status == :completed || status == :archived) ? rand(30.days).seconds.ago : nil

  task = Task.create!(
    title: "Task #{i + 1}",
    description: "Description for task #{i + 1}",
    status: status,
    priority: [ :low, :medium, :high, :urgent ].sample,
    due_date: rand(30.days).seconds.from_now,
    creator: creator,
    assignee: assignee,
    completed_at: completed_at
  )
  tasks << task
end

# Create comments
tasks.sample(10).each do |task|
  rand(1..3).times do
    Comment.create!(
      content: "Comment on #{task.title}",
      task: task,
      user: [ admin, manager, member ].sample
    )
  end
end

# Reset counter caches (they should update automatically, but ensure they're correct)
User.find_each do |user|
  User.reset_counters(user.id, :created_tasks, :assigned_tasks)
end

puts "Seeded database with:"
puts "- 3 users (admin, manager, member)"
puts "- #{Task.count} tasks"
puts "- #{Comment.count} comments"
