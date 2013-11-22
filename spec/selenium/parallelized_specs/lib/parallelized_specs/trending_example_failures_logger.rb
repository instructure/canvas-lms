require 'parallelized_specs/spec_logger_base'

class ParallelizedSpecs::TrendingExampleFailures < ParallelizedSpecs::SpecLoggerBase

  def initialize(*args)
    @passed_examples = {}
    @failed_examples = {}
    @pending_examples = {}
    @hudson_build_info = File.read("#{Rails.root}/spec/build_info.txt")
    super
  end

  def example_started(example)
    @spec_start_time = Time.now
  end

  def example_failed(example, counter, failure)
    if @spec_start_time ? total_time = (Time.now - @spec_start_time) : total_time = '0'
      if example.location != nil
        @failed_examples["#{example.location.match(/spec.*rb:\w*/).to_s}*"] = "#{example.description}*#{Date.today}*failed*#{total_time}*#{failure.exception.to_s.gsub(/\n/, "")}#{failure.exception.backtrace}*#{failure.header}*"
      end
    end
  end

  def example_passed(example)
    total_time = Time.now - @spec_start_time
    no_failure_info = '*'
    if example.location != nil
      @passed_examples["#{example.location.match(/spec.*rb:\w*/).to_s}*"] = "#{example.description}*#{Date.today}*passed*#{total_time}*#{no_failure_info}*"
    end
  end

  def dump_summary(*args)

    if File.exists?("#{Rails.root}/spec/build_info.txt")
      @hudson_build_info = File.read("#{Rails.root}/spec/build_info.txt")
    else
      @hudson_build_info = "no*hudson build*info"
    end

      [@failed_examples, @passed_examples].each do |example_results|
        unless example_results.empty?
          (example_results).each_pair do |example, details|
            @output.puts "#{example}#{details}#{@hudson_build_info}"
          end
        end
      end
      @output.flush
    end
end
