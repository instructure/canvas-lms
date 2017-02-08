module CallStackUtils
  def self.best_line_for(call_stack, except = nil)
    root = Rails.root.to_s + "/"
    lines = call_stack
    lines = lines.reject { |l| l =~ except } if except
    app_lines = lines.select { |s| s.starts_with?(root) }
    line = app_lines.grep(%r{_spec\.rb:}).first ||
           app_lines.grep(%r{/spec(_canvas?)/}).first ||
           app_lines.first ||
           lines.first
    line.sub(root, '')
  end

  # (re-)raise the exception while preserving its backtrace
  def self.raise(exception)
    super exception.class, exception.message, exception.backtrace
  end

  module ExceptionPresenter
    def exception_backtrace
      bt = super
      # for our custom matchers/validators/finders/etc., prune their lines
      # from the top of the stack so that you get a pretty/useful error
      # message and backtrace
      if exception_class_name =~ /\A(RSpec::|Selenium::WebDriver::Error::|SeleniumExtensions::)/
        line_regex = RSpec.configuration.in_project_source_dir_regex
        # remove things until we get to the frd error cause
        bt.shift while bt.first !~ line_regex || bt.first =~ %r{/spec/(support|selenium/test_setup/)}
      end
      bt
    end
  end
end

RSpec::Core::Formatters::ExceptionPresenter.prepend CallStackUtils::ExceptionPresenter
