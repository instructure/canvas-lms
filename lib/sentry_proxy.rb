require 'raven/base'

class SentryProxy
  def self.capture(exception, data)
    if exception.is_a?(String) || exception.is_a?(Symbol)
      Raven.capture_message(exception.to_s, data)
    else
      Raven.capture_exception(exception, data)
    end
  end
end
