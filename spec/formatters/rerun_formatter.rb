require "rspec/core/formatters/base_text_formatter"
require_relative "rerun_argument"

module RSpec
  class RerunFormatter < RSpec::Core::Formatters::BaseFormatter
    ::RSpec::Core::Formatters.register self, :dump_failures

    def dump_failures(notification)
      notification.failed_examples.each do |example|
        log_rerun(example)
      end
    end

    def log_rerun(example)
      path = RerunArgument.for(example)
      path_without_line_number = path.gsub(/(\.\/|[:\[].*)/, "")

      if modified_specs.include?(path_without_line_number)
        puts "not adding modified spec to rerun #{path}"
        return
      end

      msg = "adding spec to rerun #{path}"

      exception = example.metadata[:execution_result].exception
      exempt_exception_classes = [ SpecTimeLimit::Error ] # sometimes things are just a bit slow. we won't hold it against you the first time
      exempt_exception_classes << SeleniumErrorRecovery::RecoverableException if defined?(SeleniumErrorRecovery)
      if exempt_exception_classes.any? { |klass| klass === exception }
        msg += " (#{exception} exceptions are exempt from rerun thresholds)"
      end

      puts msg
    end

    def modified_specs
      @modified_specs ||= ENV["RELEVANT_SPECS"] && ENV["RELEVANT_SPECS"].split("\n") || []
    end
  end
end
