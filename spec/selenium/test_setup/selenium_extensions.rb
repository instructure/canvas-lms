require_relative "../../support/call_stack_utils"

module SeleniumExtensions
  class Error < ::RuntimeError; end
  class NestedWaitError < Error; end

  module StaleElementProtection
    attr_accessor :finder_proc

    (
      Selenium::WebDriver::Element.instance_methods(false) +
      Selenium::WebDriver::SearchContext.instance_methods -
      %i[
        initialize
        inspect
        ==
        eql?
        hash
        ref
        to_json
        as_json
      ]
    ).each do |method|
      define_method(method) do |*args|
        with_stale_element_protection do
          super(*args)
        end
      end
    end

    def with_stale_element_protection
      yield
    rescue Selenium::WebDriver::Error::StaleElementReferenceError
      raise unless finder_proc
      location = CallStackUtils.best_line_for($ERROR_INFO.backtrace, /test_setup/)
      $stderr.puts "WARNING: StaleElementReferenceError at #{location}, attempting to recover..."
      @id = finder_proc.call.ref
      retry
    end
  end

  module PreventEarlyInteraction
    attr_accessor :ready_for_interaction

    (
      Selenium::WebDriver::Driver.instance_methods(false) +
      Selenium::WebDriver::SearchContext.instance_methods -
      %i[
        initialize
        inspect
        switch_to
        manage
        get
        title
        close
        quit
        execute_script
        execute_async_script
        browser
      ]
    ).each do |method|
      define_method(method) do |*args|
        raise 'need to do a `get` before you can interact with the page' unless ready_for_interaction
        super(*args)
      end
    end
  end

  module PreventNestedWaiting
    def prevent_nested_waiting(method)
      prevent_nested_waiting!(method)
      begin
        @outer_wait_method = method
        yield
      ensure
        @outer_wait_method = nil
      end
    end

    def prevent_nested_waiting!(method)
      return unless @outer_wait_method
      return if manage.timeouts.implicit_wait == 0
      raise NestedWaitError, "`#{method}` will wait for you; don't nest it in `#{@outer_wait_method}`"
    end

    (
      %i[
        first
        find_element
        all
        find_elements
      ]
    ).each do |method|
      define_method(method) do |*args|
        prevent_nested_waiting!(method)
        super(*args)
      end
    end
  end

  module GettableTimeouts
    attr_reader :implicit_wait, :script_timeout, :page_load

    def implicit_wait=(seconds)
      super(@implicit_wait = seconds)
    end

    def script_timeout=(seconds)
      super(@script_timeout = seconds)
    end

    def page_load=(seconds)
      super(@page_load = seconds)
    end
  end

  class ReloadableCollection < ::Array
    def initialize(collection, finder_proc)
      @finder_proc = finder_proc
      replace collection
    end

    def reload!
      replace @finder_proc.call
    end
  end
end

Selenium::WebDriver::Element.prepend(SeleniumExtensions::StaleElementProtection)
Selenium::WebDriver::Driver.prepend(SeleniumExtensions::PreventEarlyInteraction)
Selenium::WebDriver::Driver.prepend(SeleniumExtensions::PreventNestedWaiting)
Selenium::WebDriver::Timeouts.prepend(SeleniumExtensions::GettableTimeouts)
