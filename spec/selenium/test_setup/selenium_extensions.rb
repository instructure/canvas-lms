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

  module FinderWaiting
    def find_element(*)
      FinderWaiting.wait_for method: :find_element do
        super
      end or raise Selenium::WebDriver::Error::NoSuchElementError
    end
    alias_method :first, :find_element

    def find_elements(*)
      result = []
      FinderWaiting.wait_for method: :find_elements do
        result = super
        result.present?
      end
      result
    end
    alias_method :all, :find_elements

    class << self
      attr_accessor :timeout

      def wait_for(method:, timeout: self.timeout, ignore: nil)
        return yield if timeout == 0
        prevent_nested_waiting(method) do
          Selenium::WebDriver::Wait.new(timeout: timeout, ignore: ignore).until do
            yield
          end
        end
      rescue Selenium::WebDriver::Error::TimeOutError
        false
      end

      def disable
        original_wait = self.timeout
        self.timeout = 0
        yield
      ensure
        self.timeout = original_wait
      end

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
        return if timeout == 0
        raise NestedWaitError, "`#{method}` will wait for you; don't nest it in `#{@outer_wait_method}`"
      end
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
Selenium::WebDriver::Element.prepend(SeleniumExtensions::FinderWaiting)
Selenium::WebDriver::Driver.prepend(SeleniumExtensions::PreventEarlyInteraction)
Selenium::WebDriver::Driver.prepend(SeleniumExtensions::FinderWaiting)
