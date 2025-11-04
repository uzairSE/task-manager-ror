# frozen_string_literal: true

# Custom matcher for counting database queries in tests
RSpec::Matchers.define :exceed_query_limit do |expected|
  supports_block_expectations

  match do |block|
    query_count = 0
    callback = lambda do |*, payload|
      query_count += 1 unless payload[:name] == 'SCHEMA' || payload[:name] == 'CACHE'
    end

    ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
      block.call
    end

    @actual = query_count
    # Return true if query_count EXCEEDS the limit (i.e., > expected)
    query_count > expected
  end

  failure_message do |block|
    "Expected more than #{expected} queries, but only #{@actual} queries were executed"
  end

  failure_message_when_negated do |block|
    "Expected at most #{expected} queries, but #{@actual} queries were executed"
  end
end
