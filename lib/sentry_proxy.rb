require 'raven/base'

class SentryProxy
  def self.capture(exception, data)
    if exception.is_a?(String) || exception.is_a?(Symbol)
      Raven.capture_message(exception.to_s, data)
    else
      Raven.capture_exception(exception, data) if reportable?(exception)
    end
  end

  # There are some errors we don't care to report to sentry because
  # they don't indicate a problem, but not all of them are necessarily
  # in the canvas codebase (and so we might not know about them at the time we
  #  configure the sentry client in an initializer).  This allows plugins and extensions
  # to register their own errors that they don't want to get reported to sentry
  def self.register_ignorable_error(error_class)
    @ignorable_errors = (self.ignorable_errors << error_class).uniq
  end

  def self.ignorable_errors
    @ignorable_errors ||= []
  end

  def self.clear_ignorable_errors
    @ignorable_errors = []
  end

  def self.reportable?(exception)
    !ignorable_errors.include?(exception.class)
  end

end
