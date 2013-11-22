require 'parallelized_specs/spec_logger_base'

class ParallelizedSpecs::SpecFailuresLogger < ParallelizedSpecs::SpecLoggerBase
  # RSpec 1: does not keep track of failures, so we do
  def example_failed(example, *args)
    if RSPEC_1
      @failed_examples ||= []
      @failed_examples << example
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
        dump_commands_to_rerun_failed_examples_rspec_1
      else
        dump_commands_to_rerun_failed_examples
      end
    end
    @output.flush
  end

  private

  def dump_commands_to_rerun_failed_examples_rspec_1
    (@failed_examples||[]).each do |example|
      file, line = example.location.to_s.split(':')
      next unless file and line
      file.gsub!(%r(^.*?/spec/), './spec/')
      @output.puts "#{ParallelizedSpecs.executable} #{file}:#{line} # #{example.description}"
    end
  end
end
