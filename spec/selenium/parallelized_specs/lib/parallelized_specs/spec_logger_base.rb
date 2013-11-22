require 'parallelized_specs'

begin
  require 'rspec/core/formatters/base_text_formatter'
  base = RSpec::Core::Formatters::BaseTextFormatter
rescue LoadError
  require 'spec/runner/formatter/base_text_formatter'
  base = Spec::Runner::Formatter::BaseTextFormatter
end
ParallelizedSpecs::SpecLoggerBaseBase = base

class ParallelizedSpecs::SpecLoggerBase < ParallelizedSpecs::SpecLoggerBaseBase
  RSPEC_1 = !defined?(RSpec::Core::Formatters::BaseTextFormatter) # do not test for Spec, this will trigger deprecation warning in rspec 2

  def initialize(*args)
    super

    @output ||= args[1] || args[0] # rspec 1 has output as second argument

    if String === @output # a path ?
      FileUtils.mkdir_p(File.dirname(@output))
      File.open(@output, 'w'){} # overwrite previous results
      @output = File.open(@output, 'a')
    elsif File === @output # close and restart in append mode
      @output.close
      @output = File.open(@output.path, 'a')
    end
  end

  def dump_summary(*args);end

  def dump_failures(*args);end

  def dump_failure(*args);end

  def dump_pending(*args);end

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
