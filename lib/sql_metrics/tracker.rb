module SqlMetrics
  class Tracker

    attr_reader :blocked_names

    attr_reader :read_counts
    attr_reader :write_counts
    attr_reader :cache_counts

    def initialize(opts=nil)
      opts ||= {}
      @blocked_names = opts.fetch(:blocked_names, [])
      @read_counts = opts.fetch(:read_counter, CanvasStatsd::Counter.new('sql_read_counter'))
      @write_counts = opts.fetch(:write_counter, CanvasStatsd::Counter.new('sql_write_counter'))
      @cache_counts = opts.fetch(:cache_counter, CanvasStatsd::Counter.new('sql_cache_counter'))
    end

    def start
      [read_counts, write_counts, cache_counts].each(&:start)
    end

    def track name, sql
      return unless sql && accepted_name?(name)

      if name.match(/CACHE/)
        cache_counts.track name
      elsif truncate(sql).match(/SELECT/) || name.match(/LOAD/)
        read_counts.track(sql)
      else
        write_counts.track(sql)
      end
    end

    def num_reads
      read_counts.finalize_count
    end

    def num_writes
      write_counts.finalize_count
    end

    def num_caches
      cache_counts.finalize_count
    end

    private

    def accepted_name?(name)
      !!(name && !blocked_names.include?(name))
    end

    def truncate(sql)
      sql ||= ''
      sql.strip[0..15]
    end

  end
end
