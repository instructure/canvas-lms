module CallStackUtils
  def self.best_line_for(call_stack)
    line = CallStackUtils.prune_backtrace!(call_stack).first
    root = Rails.root.to_s + "/"
    line.sub(root, '').sub(/:in .*/, '')
  end

  # (re-)raise the exception while preserving its backtrace
  def self.raise(exception)
    super exception.class, exception.message, exception.backtrace
  end

  APP_IGNORE_REGEX = %r{/spec/(support|selenium/test_setup/)}
  def self.prune_backtrace!(bt)
    line_regex = RSpec.configuration.in_project_source_dir_regex
    # remove things until we get to the frd error cause
    bt.shift while bt.first !~ line_regex || bt.first =~ APP_IGNORE_REGEX
    bt
  end

  module ExceptionPresenter
    def exception_backtrace
      bt = super
      # for our custom matchers/validators/finders/etc., prune their lines
      # from the top of the stack so that you get a pretty/useful error
      # message and backtrace
      if exception_class_name =~ /\A(RSpec::|Selenium::WebDriver::Error::|SeleniumExtensions::|GreatExpectations::)/
        CallStackUtils.prune_backtrace! bt
      end
      bt
    end
  end
end

ignore_regex = RSpec::CallerFilter::IGNORE_REGEX
RSpec::CallerFilter.send :remove_const, :IGNORE_REGEX
RSpec::CallerFilter::IGNORE_REGEX = Regexp.union(ignore_regex, CallStackUtils::APP_IGNORE_REGEX)
RSpec::Core::Formatters::ExceptionPresenter.prepend CallStackUtils::ExceptionPresenter
