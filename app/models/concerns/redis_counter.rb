# frozen_string_literal: true

module RedisCounter
  extend ActiveSupport::Concern

  included do
    # Define counter methods dynamically
  end

  class_methods do
    def redis_counter(name, prefix: nil)
      counter_key_prefix = prefix || model_name.singular

      define_method "#{name}_count" do
        return 0 unless id

        begin
          Redis.current.get("#{counter_key_prefix}:#{id}:#{name}")&.to_i || 0
        rescue Redis::BaseError => e
          Rails.logger.error "Redis error reading counter: #{e.message}"
          # Fallback to database count if Redis fails
          send(name).count
        end
      end

      define_method "#{name}_count=" do |value|
        return unless id

        begin
          Redis.current.set("#{counter_key_prefix}:#{id}:#{name}", value)
        rescue Redis::BaseError => e
          Rails.logger.error "Redis error setting counter: #{e.message}"
        end
      end

      define_singleton_method "increment_#{name}_for" do |record_id|
        return unless record_id

        begin
          Redis.current.incr("#{counter_key_prefix}:#{record_id}:#{name}")
        rescue Redis::BaseError => e
          Rails.logger.error "Redis error incrementing counter: #{e.message}"
        end
      end

      define_singleton_method "decrement_#{name}_for" do |record_id|
        return unless record_id

        begin
          Redis.current.decr("#{counter_key_prefix}:#{record_id}:#{name}")
        rescue Redis::BaseError => e
          Rails.logger.error "Redis error decrementing counter: #{e.message}"
        end
      end

      define_singleton_method "reset_#{name}_for" do |record_id|
        return unless record_id

        begin
          Redis.current.del("#{counter_key_prefix}:#{record_id}:#{name}")
        rescue Redis::BaseError => e
          Rails.logger.error "Redis error resetting counter: #{e.message}"
        end
      end
    end
  end
end
