# frozen_string_literal: true

require "csv"
require "stringio"

class DataExportJob < ApplicationSidekiqJob
  sidekiq_options queue: :exports, retry: 2

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user

    # Generate CSV of user's tasks
    csv_data = generate_csv(user)
    file_path = save_csv_file(user, csv_data)

    # Email download link (in real app, this would be uploaded to S3 or similar)
    send_export_email(user, file_path)
  end

  private

  def generate_csv(user)
    # Stream CSV generation instead of loading all tasks in memory
    # Use StringIO for efficient memory usage
    csv_string = StringIO.new
    csv = CSV.new(csv_string)

    csv << [ "Title", "Description", "Status", "Priority", "Due Date", "Completed At", "Created At" ]

    # Use find_each with batch processing to avoid loading all records at once
    # Process created and assigned tasks separately to maintain order
    user.created_tasks.find_each(batch_size: 500) do |task|
      csv << [
        task.title,
        task.description,
        task.status,
        task.priority,
        task.due_date&.iso8601,
        task.completed_at&.iso8601,
        task.created_at.iso8601
      ]
    end

    user.assigned_tasks.where.not(id: user.created_tasks.select(:id)).find_each(batch_size: 500) do |task|
      csv << [
        task.title,
        task.description,
        task.status,
        task.priority,
        task.due_date&.iso8601,
        task.completed_at&.iso8601,
        task.created_at.iso8601
      ]
    end

    csv_string.string
  end

  def save_csv_file(user, csv_data)
    # In production, this would be saved to S3 or similar
    file_path = Rails.root.join("tmp", "tasks_export_#{user.id}_#{Time.current.to_i}.csv")
    File.write(file_path, csv_data)
    file_path.to_s
  end

  def send_export_email(user, file_path)
    Rails.logger.info("Sending export email to #{user.email} with file #{file_path}")
    # TaskMailer.export_notification(user, file_path).deliver_now
  end
end
