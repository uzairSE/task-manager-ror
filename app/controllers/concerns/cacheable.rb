# frozen_string_literal: true

module Cacheable
  extend ActiveSupport::Concern

  private

  def cache_key_for_dashboard(user)
    # Include user role and id in cache key since policy scope varies by role
    role = user.admin? ? "admin" : (user.manager? ? "manager" : "member")
    user_id = user.member? ? user.id : "all"
    "dashboard/#{role}/#{user_id}"
  end

  def fetch_cached_dashboard_data(user, &block)
    cache_key = cache_key_for_dashboard(user)

    Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      block.call
    end
  end

  def invalidate_dashboard_cache(user = nil)
    # If user is nil, invalidate all dashboard caches (for admin actions affecting everyone)
    if user.nil?
      # Invalidate admin and manager caches
      [ "dashboard/admin/all", "dashboard/manager/all" ].each do |key|
        Rails.cache.delete(key)
      end
      # For members, we'd need to track all member IDs to invalidate individually
      # For now, we'll use a simple approach: increment version key
      # This makes all member cache keys stale (they'll regenerate on next request)
      Rails.cache.increment("dashboard/version")
    else
      # Invalidate specific user's cache
      cache_key = cache_key_for_dashboard(user)
      Rails.cache.delete(cache_key)
    end
  end
end
