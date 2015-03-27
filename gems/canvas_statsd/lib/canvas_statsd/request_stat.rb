module CanvasStatsd
  class RequestStat

    attr_accessor :sql_read_count
    attr_accessor :sql_write_count
    attr_accessor :sql_cache_count
    attr_accessor :ar_count

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
        common_key = "request.#{controller}.#{action}"
        @statsd.timing("#{common_key}.total", ms)
        @statsd.timing("#{common_key}.view", view_runtime) if view_runtime
        @statsd.timing("#{common_key}.db", db_runtime) if db_runtime
        @statsd.timing("#{common_key}.sql.read", sql_read_count) if sql_read_count
        @statsd.timing("#{common_key}.sql.write", sql_write_count) if sql_write_count
        @statsd.timing("#{common_key}.sql.cache", sql_cache_count) if sql_cache_count
        @statsd.timing("#{common_key}.active_record", ar_count) if ar_count
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
