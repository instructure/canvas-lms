require 'parallelized_specs'

module RSpec
  class ParallelizedSpecs::SlowestSpecLogger < ParallelizedSpecs::SpecLoggerBase

    def initialize(*args)
      super
      @example_times = {}
    end

    def example_started(example)
      @spec_start_time = Time.now
    end

    def example_passed(example)
      add_total_spec_time(example)
    end

    def example_failed(example, count, failure)
      add_total_spec_time(example)
    end

    def dump_summary(duration, example_count, failure_count, pending_count)
      lock_output do
        @example_times.sort.map.each { |time, example| @output.write "#{time} #{example}\n" if time.to_f > 10 }
      end
      @output.flush
    end

    def add_total_spec_time(example)
      total_time = Time.now - @spec_start_time
      @example_times[total_time] = " file: #{example.location.match(/spec.*rb:\w*/).to_s} spec: #{example.description}"
    end
  end
end