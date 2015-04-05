module Canvas
  # Simple class for shipping errors to statsd based on the format
  # propogated from callbacks on Canvas::Errors
  class ErrorStats
    def self.capture(exception, _data)
      category = exception
      unless exception.is_a?(String) || exception.is_a?(Symbol)
        category = exception.class.name
      end
      CanvasStatsd::Statsd.increment("errors.all")
      CanvasStatsd::Statsd.increment("errors.#{category}")
    end
  end
end
