# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
#
require "nokogiri"
require "selenium-webdriver"
require_relative "test_setup/custom_selenium_rspec_matchers"
require_relative "test_setup/selenium_driver_setup"
require_relative "test_setup/selenium_extensions"

if ENV["TESTRAIL_RUN_ID"]
  require "testrailtagging"
  RSpec.configure do |config|
    TestRailRSpecIntegration.register_rspec_integration(config, :canvas, add_formatter: false)
  end
elsif ENV["TESTRAIL_ENTRY_RUN_ID"]
  require "testrailtagging"
  RSpec.configure do |config|
    TestRailRSpecIntegration.add_rspec_callback(config, :canvas)
  end
end

Dir[File.dirname(__FILE__) + "/test_setup/common_helper_methods/*.rb"].each { |file| require file }

RSpec.configure do |config|
  config.before :suite do
    # For flakey spec catcher: if server and driver are already initialized, reuse instead of starting another instance
    SeleniumDriverSetup.run unless SeleniumDriverSetup.server.present? && SeleniumDriverSetup.driver.present?
  end
end

module SeleniumDependencies
  include SeleniumDriverSetup
  include OtherHelperMethods
  include CustomSeleniumActions
  include CustomSeleniumRSpecMatchers
  include CustomAlertActions
  include CustomPageLoaders
  include CustomScreenActions
  include CustomValidators
  include CustomWaitMethods
  include CustomDateHelpers
  include LoginAndSessionMethods
end

# synchronize db connection methods for a modicum of thread safety
module SynchronizeConnection
  %w[cache_sql execute exec_cache exec_no_cache query transaction].each do |method|
    class_eval <<~RUBY, __FILE__, __LINE__ + 1
      def #{method}(...)                                         # def execute(...)
        SeleniumDriverSetup.request_mutex.synchronize { super }  #   SeleniumDriverSetup.request_mutex.synchronize { super }
      end                                                        # end
    RUBY
  end
end

shared_context "in-process server selenium tests" do
  include SeleniumDependencies

  # set up so you can use rails urls helpers in your selenium tests
  include Rails.application.routes.url_helpers

  prepend_before :all do
    # building the schema is currently very slow.
    # this ensures the schema is built before specs are run to avoid timeouts
    CanvasSchema.graphql_definition
  end

  prepend_before do
    resize_screen_to_standard
    SeleniumDriverSetup.allow_requests!
    driver.ready_for_interaction = false # need to `get` before we do anything selenium-y in a spec
  end

  around :all do |group|
    GreatExpectations.with_config(MISSING: :raise) do
      group.run_examples
    end
  end

  append_before :all do
    retry_count = 0
    begin
      default_url_options[:host] = app_host_and_port
      close_modal_if_present { resize_screen_to_standard } unless @driver.nil?
    rescue
      if maybe_recover_from_exception($ERROR_INFO) && (retry_count += 1) < 3
        retry
      else
        raise
      end
    end
  end

  append_before do
    EncryptedCookieStore.test_secret = SecureRandom.hex(64)
    enable_forgery_protection
  end

  before do
    raise "all specs need to use transactional fixtures" unless use_transactional_tests

    allow(HostUrl).to receive_messages(default_host: app_host_and_port,
                                       file_host: app_host_and_port)
  end

  before(:all) do
    ActiveRecord::Base.connection.class.prepend(SynchronizeConnection)
  end

  after do
    begin
      clear_timers!
      # while disallow_requests! would generally get these, there's a small window
      # between the ajax request starting up and the middleware actually processing it
      wait_for_ajax_requests
    rescue Selenium::WebDriver::Error::WebDriverError
      # we want to ignore selenium errors when attempting to wait here
    ensure
      SeleniumDriverSetup.disallow_requests!
    end

    # we don't want to combine this into the above block to avoid x-test pollution
    # if a previous step fails
    begin
      clear_local_storage
    rescue Selenium::WebDriver::Error::WebDriverError
      # we want to ignore selenium errors when attempting to wait here
    end

    # we don't want to combine this into the above block to avoid x-test pollution
    # if a previous step fails
    begin
      driver.session_storage.clear
    rescue Selenium::WebDriver::Error::WebDriverError
      # we want to ignore selenium errors when attempting to wait here
    end
  end

  # logs everything that showed up in the browser console during selenium tests
  after do |example|
    if example.exception
      html = f("body").attribute("outerHTML")
      document = Nokogiri::HTML5(html)
      example.metadata[:page_html] = document.to_html
    end

    browser_logs = driver.logs.get(:browser) rescue nil

    # log INSTUI deprecation warnings
    if browser_logs.present?
      spec_file = example.file_path.sub(%r{.*spec/selenium/}, "")
      deprecations = browser_logs.select { |l| l.message =~ /\[.*deprecated./ }.map do |l|
        ">>> #{spec_file}: \"#{example.description}\": #{driver.current_url}: #{l.message.gsub(/.*Warning/, "Warning")}"
      end
      puts "\n", deprecations.uniq
    end

    if !example.metadata[:ignore_js_errors] && browser_logs.present?
      msg = "browser console logs for \"#{example.description}\":\n" + browser_logs.map(&:message).join("\n\n")
      Rails.logger.info(msg)
      # puts msg

      # if you run into something that doesn't make sense t
      browser_errors_we_dont_care_about = [
        "Warning: Can't perform a React state update on an unmounted component",
        "Replacing React-rendered children with a new root component.",
        "A theme registry has already been initialized.",
        "Blocked attempt to show a 'beforeunload' confirmation panel for a frame that never had a user gesture since its load",
        "Error: <path> attribute d: Expected number",
        "elements with non-unique id #",
        "Failed to load http://www.example.com/",
        "Failed to load http://example.com/",
        "Uncaught Error: cannot call methods on timeoutTooltip prior to initialization; attempted to call method 'close'",
        "Failed to load resource",
        "Deprecated use of magic jQueryUI widget markup detected",
        "Uncaught SG: Did not receive drive#about kind when fetching import",
        "Failed prop type",
        "Warning: Failed propType",
        "Warning: React.render is deprecated",
        "Warning: ReactDOMComponent: Do not access .getDOMNode()",
        "Please either add a 'report-uri' directive, or deliver the policy via the 'Content-Security-Policy' header.",
        "isMounted is deprecated. Instead, make sure to clean up subscriptions and pending requests in componentWillUnmount to prevent memory leaks",
        "https://www.gstatic.com/_/apps-viewer/_/js/k=apps-viewer.standalone.en_US",
        "In webpack, loading timezones on-demand is not",
        "Uncaught RangeError: Maximum call stack size exceeded",
        "Warning: React does not recognize the `%s` prop on a DOM element.",
        # For InstUI upgrade to 5.36. These should probably be fixed eventually.
        "Warning: [Focusable] Exactly one focusable child is required (0 found).",
        # COMMS-1815: Meeseeks should fix this one on the permissions page
        "Warning: [Select] The option 'All Roles' doesn't correspond to an option.",
        "Warning: [Focusable] Exactly one tabbable child is required (0 found).",
        "Warning: [Alert] live region must have role='alert' set on page load in order to announce content",
        "[View] display style is set to 'inline'",
        "Uncaught TypeError: Failed to fetch",
        "Unexpected end of JSON input",
        "The google.com/jsapi JavaScript loader is deprecat",
        "Uncaught Error: Not Found", # for canvas-rce when no backend is set up
        "Uncaught Error: Minified React error #188",
        "Uncaught Error: Minified React error #200", # this is coming from canvas-rce, but we should fix it
        "Uncaught Error: Loading chunk", # probably happens when the test ends when the browser is still loading some JS
        "Access to Font at 'http://cdnjs.cloudflare.com/ajax/libs/mathjax/",
        "Access to XMLHttpRequest at 'http://www.example.com/' from origin",
        "The user aborted a request", # The server doesn't respond fast enough sometimes and requests can be aborted. For example: when a closing a dialog.
        # Is fixed in Chrome 109, remove this once upgraded to or above Chrome 109 https://bugs.chromium.org/p/chromium/issues/detail?id=1307772
        "Found a 'popup' attribute. If you are testing the popup API, you must enable Experimental Web Platform Features.",
        "Uncaught DOMException: play() failed because the user didn't interact with the document first.",
        "security - Refused to frame 'https://drive.google.com/' because an ancestor violates the following Content Security Policy directive: \"frame-ancestors https://docs.google.com\".",
        "This file should be served over HTTPS." # tests are not run over https, this error is expected
      ].freeze

      javascript_errors = browser_logs.select do |e|
        e.level == "SEVERE" &&
          e.message.present? &&
          browser_errors_we_dont_care_about.none? { |s| e.message.include?(s) }
      end

      # Crystalball is going to get a few JS errors when using istanbul-instrumenter
      if javascript_errors.present? && ENV["CRYSTALBALL_MAP"] != "1"
        raise javascript_errors.map(&:message).join("\n\n")
      end
    end
  end

  after(:all) do
    ENV.delete("CANVAS_CDN_HOST")
  end
end
