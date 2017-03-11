require_relative "./base_formatter"
require "escape_code"

module ErrorContext
  class HTMLPageFormatter < BaseFormatter
    extend Forwardable

    def example_finished(*)
      super
      write_error_page if summary.example.exception
    rescue
      $stderr.puts "There was an error generating the error page, sadlol: #{$ERROR_INFO}"
    end

    def escape_code(code)
      EscapeCode::HtmlFormatter.new(code).generate.html_safe
    end

    def escape_code_stylesheet
      EscapeCode::HtmlFormatter.new("").generate_stylesheet
    end

    def write_error_page
      # make a nice little html file for jenkins
      File.open(File.join(errors_path, "index.html"), "w") do |file|
        file.write error_page_content
      end
    end

    def error_page_content
      return if summary.discard?

      output_buffer = nil
      example = summary.example
      formatted_exception = ::RSpec::Core::Formatters::ExceptionPresenter.new(example.exception, example).fully_formatted(nil)
      error_template.result(binding)
    end

    def recent_spec_runs
      return "-" if ErrorSummary.recent_spec_runs.empty?

      base_path = "../" + ("../" * summary.spec_path.count("/"))
      errors = ErrorSummary.recent_spec_runs.reverse.map do |run|
        location = ERB::Util.html_escape(run[:location])
        if run[:pending]
          "bin/rspec #{location} (pending)"
        elsif run[:exception]
          "bin/rspec <a href=\"#{base_path + location}/index.html\">#{location}</a> (failed)"
        else
          "bin/rspec #{location}"
        end
      end.join("<br>")

      "(newest)<br>#{errors}<br>(oldest)".html_safe
    end

    def error_template
      @error_template ||= begin
        layout_path = File.join(File.dirname(__FILE__), "html_page_formatter", "template.html.erb")
        ActionView::Template::Handlers::Erubis.new(File.read(layout_path))
      end
    end
  end
end
