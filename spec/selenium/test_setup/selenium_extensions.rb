# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require_relative "../../support/call_stack_utils"
require_relative "selenium_driver_setup"
require_relative "common_helper_methods/custom_wait_methods"

module SeleniumExtensions
  class Error < ::RuntimeError; end

  class NestedWaitError < Error; end

  module UnexpectedPageReloadProtection
    include CustomWaitMethods

    def with_page_reload_protection(bridge)
      yield

      begin
        wait_for_initializers(bridge)
        wait_for_ajaximations(bridge)
      rescue Selenium::WebDriver::Error::UnexpectedAlertOpenError
        # If there is an alert open, the calling code needs to accept it, so we won't be reloading
        # as part of this event. Once the alert is accepted or discarded, we will then wait for
        # page reloads or outstanding AJAX requests.
        nil
      end
    end
  end

  module UnexpectedPageReloadProtectionActionBuilder
    include UnexpectedPageReloadProtection

    def perform(*args)
      with_page_reload_protection(@bridge) { super(*args) }
    end
  end

  module UnexpectedPageReloadProtectionAlert
    include UnexpectedPageReloadProtection

    def accept(*args)
      with_page_reload_protection(@bridge) { super(*args) }
    end
  end

  module UnexpectedPageReloadProtectionElement
    include UnexpectedPageReloadProtection

    def click(*args)
      with_page_reload_protection(driver) { super(*args) }
    end

    def send_keys(*args)
      with_page_reload_protection(driver) { super(*args) }
    end

    def submit(*args)
      with_page_reload_protection(driver) { super(*args) }
    end
  end

  module ElementNotInteractableProtection
    include SeleniumDriverSetup

    def click(*args)
      to_fail = false

      begin
        super
      rescue Selenium::WebDriver::Error::ElementNotInteractableError => e
        raise e if to_fail

        to_fail = true

        begin
          Selenium::WebDriver::Wait.new(timeout: 2).until do
            displayed? && enabled?
          end
          # https://bugs.chromium.org/p/chromedriver/issues/detail?id=3504
          # bug in chrome, not scrolling to elements before attempting click. This will scroll to element
          # then retry the click.
          driver.action.move_to(self).perform
        rescue
          raise e
        end

        retry
      end
    end
  end

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

      location = CallStackUtils.best_line_for($ERROR_INFO.backtrace)
      warn "WARNING: StaleElementReferenceError at #{location.first}, attempting to recover..."
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
        capabilities
      ]
  ).each do |method|
      define_method(method) do |*args|
        raise Error, "need to do a `get` before you can interact with the page" unless ready_for_interaction

        super(*args)
      end
    end
  end

  module FinderWaiting
    def find_element(*args)
      FinderWaiting.wait_for method: :find_element do
        super
      end or raise Selenium::WebDriver::Error::NoSuchElementError, "Unable to locate element: #{args.map(&:inspect).join(", ")}"
    end
    alias_method :first, :find_element

    def find_elements(*args)
      result = []
      FinderWaiting.wait_for method: :find_elements do
        result = super
        result.present?
      end
      result.present? or raise Selenium::WebDriver::Error::NoSuchElementError, "Unable to locate element: #{args.map(&:inspect).join(", ")}"
      result
    end
    alias_method :all, :find_elements

    class << self
      attr_accessor :timeout

      def wait_for(method:, timeout: self.timeout, ignore: nil, &block)
        return yield if timeout == 0

        prevent_nested_waiting(method) do
          Selenium::WebDriver::Wait.new(timeout:, ignore:).until(&block)
        end
      rescue Selenium::WebDriver::Error::TimeoutError
        false
      end

      def disable
        original_wait = timeout
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
      super()
      @finder_proc = finder_proc
      replace collection
    end

    def reload!
      replace @finder_proc.call
    end

    def with_stale_element_protection
      yield(self)
    rescue Selenium::WebDriver::Error::StaleElementReferenceError
      reload!
      retry
    end
  end
end

Selenium::WebDriver::Alert.prepend(SeleniumExtensions::UnexpectedPageReloadProtectionAlert)
Selenium::WebDriver::Element.prepend(SeleniumExtensions::ElementNotInteractableProtection)
Selenium::WebDriver::Element.prepend(SeleniumExtensions::StaleElementProtection)
Selenium::WebDriver::Element.prepend(SeleniumExtensions::FinderWaiting)
Selenium::WebDriver::Element.prepend(SeleniumExtensions::UnexpectedPageReloadProtectionElement)
Selenium::WebDriver::Driver.prepend(SeleniumExtensions::PreventEarlyInteraction)
Selenium::WebDriver::Driver.prepend(SeleniumExtensions::FinderWaiting)
Selenium::WebDriver::ActionBuilder.prepend(SeleniumExtensions::UnexpectedPageReloadProtectionActionBuilder)
