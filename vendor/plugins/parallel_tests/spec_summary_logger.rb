require 'parallel_specs'
require File.join(File.dirname(__FILE__), 'spec_logger_base')

class ParallelSpecs::SpecSummaryLogger < ParallelSpecs::SpecLoggerBase
  def initialize(options, output=nil)
    super
    @passed_examples = []
    @pending_examples = []
    @failed_examples = []
  end

  def example_passed(example)
    @passed_examples << example
  end

  def example_pending(*args)
    @pending_examples << args
  end

  def example_failed(example, count, failure)
    @failed_examples << failure
  end

  def dump_summary(duration, example_count, failure_count, pending_count)
    lock_output do
      @output.puts "#{ @failed_examples.size }"
    end
    @output.flush
  end

  def dump_failure(*args)
    lock_output do
      @output.print ''
    end
    @output.flush
  end

end
