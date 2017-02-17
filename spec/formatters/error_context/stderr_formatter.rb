require_relative "./base_formatter"
require "escape_code"

module ErrorContext
  class StderrFormatter < BaseFormatter
    def example_finished(*)
      super
      write_to_stderr
    end

    def write_to_stderr
      output = []

      # always send js errors to stdout, even if the spec passed. we have to
      # empty the JSErrorCollector anyway, so we might as well show it.
      summary.js_errors&.each do |error|
        output << "  JS Error: #{error['errorMessage']} (#{error['sourceName']}:#{error['lineNumber']})"
      end

      output << "  Screenshot: #{File.join(errors_path, summary.screenshot_name)}" if summary.screenshot_name
      output << "  Screen capture: #{File.join(errors_path, summary.screen_capture_name)}" if summary.screen_capture_name

      if output.any?
        output.unshift summary.example.location_rerun_argument
        $stderr.puts output.join("\n")
      end
    end
  end
end
