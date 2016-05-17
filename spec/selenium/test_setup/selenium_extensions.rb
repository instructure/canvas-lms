require_relative "../../support/call_stack_utils"

module SeleniumExtensions
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
        begin
          super(*args)
        rescue Selenium::WebDriver::Error::StaleElementReferenceError
          raise unless finder_proc
          location = CallStackUtils.best_line_for($ERROR_INFO.backtrace, /test_helper/)
          $stderr.puts "WARNING: StaleElementReferenceError at #{location}, attempting to recover..."
          @id = finder_proc.call.ref
          retry
        end
      end
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
end

Selenium::WebDriver::Element.prepend(SeleniumExtensions::StaleElementProtection)
Selenium::WebDriver::Driver.prepend(SeleniumExtensions::PreventEarlyInteraction)
