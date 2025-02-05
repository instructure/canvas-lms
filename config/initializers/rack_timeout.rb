Rails.application.config.middleware.insert_before Rack::Runtime, Rack::Timeout, service_timeout: 50
class SlowTransactionError < RuntimeError
  attr :backtrace
  def initialize(backtrace)
    @backtrace = backtrace
  end
end
Rack::Timeout.register_state_change_observer(:check_for_slow_requests) do |env|
  unless env["sentry_sent"]
    info = env[::Rack::Timeout::ENV_INFO_KEY]
    request_id = info.id
    if info.service && info.service > 30
      env["sentry_sent"] = true
      begin
        slow_thread = Thread.list.find { |thread| thread.thread_variable_get("request_id") == request_id}
        slow_thread.thread_variable_get('sentry_hub').capture_exception(SlowTransactionError.new(slow_thread.backtrace))
      rescue
         # Ignored
      end
    end
  end
end

