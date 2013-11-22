require 'parallelized_specs/spec_failures_logger'

class ParallelizedSpecs::SpecSummaryLogger < ParallelizedSpecs::SpecLoggerBase
  # RSpec 1: dumps 1 failed spec
  def dump_failure(*args)
    lock_output do
      super
    end
    @output.flush
  end

  # RSpec 2: dumps all failed specs
  def dump_failures(*args)
    lock_output do
      super
    end
    @output.flush
  end
end
