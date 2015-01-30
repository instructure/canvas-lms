module CanvasStatsd
  class RequestStat

    def initialize(name, start, finish, id, payload, statsd=CanvasStatsd::Statsd)
      @name = name
      @start = start
      @finish = finish
      @id = id
      @payload = payload
      @statsd = statsd
    end

    def report
      if controller && action
        @statsd.timing("request.#{controller}.#{action}.total", ms)
        @statsd.timing("request.#{controller}.#{action}.view", view_runtime) if view_runtime
        @statsd.timing("request.#{controller}.#{action}.db", db_runtime) if db_runtime
      end
    end

    def db_runtime
      @payload.fetch(:db_runtime, nil)
    end

    def view_runtime
      @payload.fetch(:view_runtime, nil)
    end

    def controller
     @payload.fetch(:params, {})['controller']
    end

    def action
      @payload.fetch(:params, {})['action']
    end

    def ms
      if (!@finish || !@start)
        return 0
      end
      (@finish - @start) * 1000
    end

  end
end
