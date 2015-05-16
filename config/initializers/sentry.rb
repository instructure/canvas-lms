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
    config.silence_ready = true
    config.dsn = settings[:dsn]
    config.tags = settings.fetch(:tags, {}).merge('canvas_revision' => Canvas.revision)
    config.sanitize_fields += Rails.application.config.filter_parameters.map(&:to_s)
    config.sanitize_credit_cards = false
  end

  Rails.configuration.to_prepare do
    Canvas::Errors.register!(:sentry_notification) do |exception, data|
      setting = Setting.get("sentry_error_logging_enabled", 'true')
      SentryProxy.capture(exception, data) if setting == 'true'
    end
  end

end
