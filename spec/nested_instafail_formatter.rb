require 'spec/runner/formatter/nested_text_formatter'

module RSpec
  class NestedInstafailFormatter < Spec::Runner::Formatter::NestedTextFormatter
    def example_failed(example, counter, failure)
      super
      dump_failure(counter, failure)
      output.puts
    end
  end
end
