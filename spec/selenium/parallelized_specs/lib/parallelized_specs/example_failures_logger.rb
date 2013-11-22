require 'parallelized_specs/spec_logger_base'

class ParallelizedSpecs::ExampleRerunFailuresLogger < ParallelizedSpecs::SpecLoggerBase

  def example_failed(example, *args)
    if RSPEC_1
      if example.location != nil
        unless !!self.example_group.nested_descriptions.to_s.match(/shared/) || !!self.instance_variable_get(:@example_group).examples.last.location.match(/helper/)
          @failed_examples ||= []
          @failed_examples << "#{example.location.match(/spec.*\d/).to_s} "
        end
      end
      else
      super
    end
  end

# RSpec 1: dumps 1 failed spec
  def dump_failure(*args)
  end

# RSpec 2: dumps all failed specs
  def dump_failures(*args)
  end

  def dump_summary(*args)
    lock_output do
      if RSPEC_1
        @output.write "#{@failed_examples.to_s}"
      end
    end
    @output.flush
  end
end

