Rails.application.config.middleware.insert_before Rack::Runtime, Rack::Timeout, service_timeout: 55
class SlowTransactionError < RuntimeError
  attr_reader :backtrace, :duration

  def initialize(backtrace, duration)
    @backtrace = backtrace
    @duration = duration
  end

  def message
    "Request took too long (#{duration}s)."
  end
end

Rack::Timeout.register_state_change_observer(:check_for_slow_requests) do |env|
  unless env["sentry_sent"]
    info = env[::Rack::Timeout::ENV_INFO_KEY]
    request_id = info.id
    slow_threshold = ENV.fetch("SLOW_QUERY_THRESHOLD", 50).to_i
    actual_time = info.service

    if actual_time && actual_time > slow_threshold
      env["sentry_sent"] = true
      begin
        slow_thread = Thread.list.find { |thread| thread.thread_variable_get("request_id") == request_id}
        slow_thread.thread_variable_get('sentry_hub').capture_exception(SlowTransactionError.new(slow_thread.backtrace, actual_time))
      rescue
         # Ignored
      end
    end
  end
end
