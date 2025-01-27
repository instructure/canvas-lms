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
    request_id = env["action_dispatch.request_id"]
    if info.service && info.service > 15
      env["sentry_sent"] = true
      backtrace = Thread.list.find { |thread| thread.thread_variable_get("request_id") == request_id}.backtrace
      Sentry.capture_exception(SlowTransactionError.new(backtrace))
    end
  end
end
