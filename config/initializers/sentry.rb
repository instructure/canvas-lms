# This initializer is for the Sentry exception tracking system.
#
# "Raven" is the ruby library that is the client to sentry, and it's
# config file would be "config/raven.yml". If that config doesn't exist,
# nothing happens.  If it *does*, we register a callback with Canvas::Errors
# so that every time an exception is reported, we can fire off a sentry
# call to track it and aggregate it for us.
settings = ConfigFile.load("raven")

if settings.present?
  require "raven/base"
  Raven.configure do |config|
    config.dsn = settings[:dsn]
  end

  Canvas::Errors.register!(:sentry_notification) do |exception, data|
    setting = Setting.get("sentry_error_logging_enabled", 'true')
    if setting == 'true'
      if exception.is_a?(String) || exception.is_a?(Symbol)
        Raven.capture_message(exception, data)
      else
        Raven.capture_exception(exception, data)
      end
    end
  end
end
