module Canvas
  module EventStreamLogger
    def self.logger
      Rails.logger
    end

    def self.info(type, identifier, operation, record)
      logger.info "[#{type}:INFO] #{identifier}:#{operation} #{record}"
    end

    def self.error(type, identifier, operation, record, message)
      logger.error "[#{type}:ERROR] #{identifier}:#{operation} #{record} [#{message}]"
      CanvasStatsd::Statsd.increment("event_stream_failure.stream.#{CanvasStatsd::Statsd.escape(identifier)}")
      if message.blank?
        CanvasStatsd::Statsd.increment("event_stream_failure.exception.blank")
      elsif message.include?("No live servers")
        CanvasStatsd::Statsd.increment("event_stream_failure.exception.no_live_servers")
      elsif message.include?("Unavailable")
        CanvasStatsd::Statsd.increment("event_stream_failure.exception.unavailable")
      else
        CanvasStatsd::Statsd.increment("event_stream_failure.exception.other")
      end
    end
  end
end
