
require 'rspec/core/formatters/base_text_formatter'
module RSpec
  class NestedInstafailFormatter < RSpec::Core::Formatters::BaseTextFormatter
    def example_failed(example)
      super
      dump_failure(example, index)
      output.puts
    end

    def dump_summary(duration, example_count, failure_count, pending_count)
      dump_failures
    end
  end
end
