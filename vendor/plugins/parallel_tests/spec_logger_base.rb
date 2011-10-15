require 'parallel_specs'

begin
  require 'rspec/core/formatters/progress_formatter'
  base = RSpec::Core::Formatters::ProgressFormatter
rescue LoadError
  require 'spec/runner/formatter/progress_bar_formatter'
  base = Spec::Runner::Formatter::BaseTextFormatter
end
ParallelSpecs::SpecLoggerBaseBase = base

class ParallelSpecs::SpecLoggerBase < ParallelSpecs::SpecLoggerBaseBase
  def initialize(options, output=nil)
    output ||= options # rspec 2 has output as first argument

    if String === output
      FileUtils.mkdir_p(File.dirname(output))
      File.open(output, 'w'){} # overwrite previous results
      @output = File.open(output, 'a')
    elsif File === output
      output.close # close file opened with 'w'
      @output = File.open(output.path, 'a')
    else
      @output = output
    end

    @failed_examples = [] # only needed for rspec 2
  end

  def example_started(*args)
  end

  def example_passed(example)
  end

  def example_pending(*args)
  end

  def example_failed(*args)
  end

  def start_dump(*args)
  end

  def dump_summary(*args)
  end

  def dump_pending(*args)
  end

  def dump_failure(*args)
  end

  #stolen from Rspec
  def close
    @output.close  if (IO === @output) & (@output != $stdout)
  end

  # do not let multiple processes get in each others way
  def lock_output
    if File === @output
      begin
        @output.flock File::LOCK_EX
        yield
      ensure
        @output.flock File::LOCK_UN
      end
    else
      yield
    end
  end
end
