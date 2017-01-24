require 'rspec/core/formatters/base_text_formatter'

module RSpec
  class RerunFormatter < RSpec::Core::Formatters::BaseFormatter
    ::RSpec::Core::Formatters.register self, :dump_failures

    def dump_failures(notification)
      failed_examples = notification.failed_examples
      return if failed_examples.empty?
      failed_example_data = extract_example_data(failed_examples)
      unique_failed_example_data = uniqued_by_path(failed_example_data)
      unique_failed_example_data.each do |example_data|
        log_rerun(example_data)
      end
    end

    def log_rerun(example_data)
      path = example_data[:path]
      path_without_line_number = path.gsub(/(\.\/|\:\d+)/, "")

      if modified_specs.include?(path_without_line_number)
        puts "[#{path_without_line_number} is not eligible for rerunning because it was modified in this commit]"
        return
      end

      msg = "[SPOTBOT] adding spec to rerun #{path}"

      exempt_exception_classes = [ SpecTimeLimit::Error ] # sometimes things are just a bit slow. we won't hold it against you the first time
      exempt_exception_classes << SeleniumErrorRecovery::RecoverableException if defined?(SeleniumErrorRecovery)
      if exempt_exception_classes.any? { |klass| klass === example_data[:exception] }
        msg += " [#{example_data[:exception].class} exceptions are exempt from rerun thresholds]"
      end

      puts msg
    end

    def modified_specs
      @modified_specs ||= ENV["RELEVANT_SPECS"] && ENV["RELEVANT_SPECS"].split("\n") || []
    end

    def extract_example_data(failed_examples)
      failed_examples.map do |example|
        {
          path: extract_spec_location(example.metadata),
          exception: example.metadata[:execution_result].exception
        }
      end
    end

    def uniqued_by_path(failed_example_data)
      # this trims down extra specs from being run
      # each spec failing in a shared example will give the base file invoking and line number
      # if 1 spec fails in a shared group they all have to be rerun so each spec that says it
      # failed in a group we only account for once
      unique_spec_paths = []
      unique_failed_example_data = []
      failed_example_data.each do |example_data|
        path = example_data[:path]
        if unique_spec_paths.include?(path)
          puts "[SPOTBOT] already being rerun #{path}"
        else
          unique_spec_paths << path
          unique_failed_example_data << example_data
        end
      end
      unique_failed_example_data
    end

    # RSpec natively compact duplicate file paths
    # Run options: include {:locations=>{"./spec/models/quizzes/quiz_question/answer_parsers/matching_spec.rb"=>[27, 27, 27, 27]}}

    def extract_spec_location(metadata)
      until metadata[:location] =~ /_spec.rb:\d+$/ do
        metadata = metadata[:parent_example_group] || metadata[:example_group]
        # raise 'No spec file could be found in meta data!' unless metadata
      end
      metadata[:location]
    end
  end
end
