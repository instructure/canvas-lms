Rails.application.config.middleware.insert_before Rack::Runtime, Rack::Timeout, service_timeout: 55
class SlowTransactionError < RuntimeError; end
Rack::Timeout.register_state_change_observer(:check_for_slow_requests) do |env|
  unless env["sentry_sent"]
    info = env[::Rack::Timeout::ENV_INFO_KEY]
    if info.service && info.service > 15
      Sentry.capture_exception(SlowTransactionError.new)
      env["sentry_sent"] = true
    end
  end
end
