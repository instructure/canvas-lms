require 'parallelized_specs/spec_logger_base'


module RSpec
  class ParallelizedSpecs::FailuresFormatter < ParallelizedSpecs::SpecLoggerBase

    def example_failed(example, counter, failure)
    lock_output do
        @output.puts retry_command(example)
      end
    end

    def dump_summary(duration, example_count, failure_count, pending_count)
     ;
    end

    def dump_failures(*args)
      ;
    end

    def dump_failure(*args)
      ;
    end

    def dump_pending(*args)
      ;
    end


    def retry_command(example)
      puts "Storing #{example_group.location} for a post build rerun attempt"
      spec_file = example_group.location.match(/.*rb/).to_s
      spec_name = example.description
      "SPEC=#{spec_file} SPEC_OPTS=\"-e \\\"#{spec_name}\\\"\""
    end
  end
end
