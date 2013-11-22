require 'parallelized_specs'
require File.join(File.dirname(__FILE__), 'spec_logger_base')

class ParallelizedSpecs::SpecErrorLogger < ParallelizedSpecs::SpecLoggerBase
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
      env_test_number = ENV['TEST_ENV_NUMBER']
      env_test_number = 1 if ENV['TEST_ENV_NUMBER'].blank?
      @output.puts ""
      @output.puts ""
      @output.puts "FOR TEST EXECUTOR #{env_test_number}: #{@failed_examples.size} failed, #{@passed_examples.size} passed:"
      @failed_examples.each.with_index do |failure, i|
        @output.puts ""
        @output.puts "#{ i + 1 })"
        @output.puts failure.header
        unless failure.exception.nil?
          @output.puts failure.exception.to_s
          failure.exception.backtrace.each do |caller|
            @output.puts caller
          end
        end
      end
    end
    @output.flush
  end
end
