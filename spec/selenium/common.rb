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
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "nokogiri"
require "selenium-webdriver"
require "socket"
require "timeout"
require "sauce_whisk"
require_relative 'test_setup/custom_selenium_rspec_matchers'
require_relative 'test_setup/selenium_driver_setup'
require_relative 'test_setup/selenium_extensions'

if ENV["TESTRAIL_RUN_ID"]
  require 'testrailtagging'
  RSpec.configure do |config|
    TestRailRSpecIntegration.register_rspec_integration(config,:canvas, add_formatter: false)
  end
elsif ENV["TESTRAIL_ENTRY_RUN_ID"]
  require "testrailtagging"
  RSpec.configure do |config|
    TestRailRSpecIntegration.add_rspec_callback(config, :canvas)
  end
end

Dir[File.dirname(__FILE__) + '/test_setup/common_helper_methods/*.rb'].each {|file| require file }

module SeleniumErrorRecovery
  class RecoverableException < StandardError
    extend Forwardable
    def_delegators :@exception, :class, :message, :backtrace

    def initialize(exception)
      @exception = exception
    end
  end

  # this gets called wherever an exception happens (example, before/after/around, each/all)
  #
  # the example will still fail, but if we recover successfully, subsequent
  # specs should pass. additionally, the rerun phase will exempt this
  # failure from the threshold, since it's not a problem with the spec
  # per se
  def set_exception(exception, *args)
    exception = RecoverableException.new(exception) if maybe_recover_from_exception(exception)
    super exception, *args
  end

  def maybe_recover_from_exception(exception)
    case exception
    when Errno::ENOMEM
      # no sense trying anymore, give up and hope that other nodes pick up the slack
      puts "Error: got `#{exception}`, aborting"
      RSpec.world.wants_to_quit = true
    when EOFError, Errno::ECONNREFUSED, Net::ReadTimeout
      return false if SeleniumDriverSetup.saucelabs_test_run?
      return false if RSpec.world.wants_to_quit
      return false unless exception.backtrace.grep(/selenium-webdriver/).present?

      puts "SELENIUM: webdriver is misbehaving.  Will try to re-initialize."
      SeleniumDriverSetup.reset!
      return true
    end
    false
  end
end
RSpec::Core::Example.prepend(SeleniumErrorRecovery)

if defined?(TestQueue::Runner::RSpec::LazyGroups)
  # because test-queue's lazy loading requires this file *after* the before
  # :suite hooks run, we can't do this in such a hook... so just do it as
  # soon as this file is required. the TEST_ENV_NUMBER check ensures the
  # background file loader doesn't also fire up firefox and a webserver
  SeleniumDriverSetup.run if ENV["TEST_ENV_NUMBER"]
else
  RSpec.configure do |config|
    config.before :suite do
      SeleniumDriverSetup.run
    end
  end
end

module SeleniumDependencies
  include SeleniumDriverSetup
  include OtherHelperMethods
  include CustomSeleniumActions
  include CustomAlertActions
  include CustomPageLoaders
  include CustomScreenActions
  include CustomValidators
  include CustomWaitMethods
  include CustomDateHelpers
  include LoginAndSessionMethods
  include SeleniumErrorRecovery
end

shared_context "in-process server selenium tests" do
  include SeleniumDependencies

  # set up so you can use rails urls helpers in your selenium tests
  include Rails.application.routes.url_helpers

  prepend_before :each do
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

  append_before :each do
    EncryptedCookieStore.test_secret = SecureRandom.hex(64)
    enable_forgery_protection
  end

  before do
    raise "all specs need to use transactional fixtures" unless use_transactional_tests

    allow(HostUrl).to receive(:default_host).and_return(app_host_and_port)
    allow(HostUrl).to receive(:file_host).and_return(app_host_and_port)
  end

  # synchronize db connection methods for a modicum of thread safety
  module SynchronizeConnection
    %w{execute exec_cache exec_no_cache query transaction}.each do |method|
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{method}(*)
          SeleniumDriverSetup.request_mutex.synchronize { super }
        end
      RUBY
    end
  end

  before(:all) do
    ActiveRecord::Base.connection.class.prepend(SynchronizeConnection)
  end

  # tricksy tricksy. grab the current connection, and then always return the same one
  # (even if on a different thread - i.e. the server's thread), so that it will be in
  # the same transaction and see the same data
  before do
    @db_connection = ActiveRecord::Base.connection
    @dj_connection = Delayed::Backend::ActiveRecord::Job.connection

    allow(ActiveRecord::Base).to receive(:connection).and_return(@db_connection)
    allow_any_instance_of(Switchman::ConnectionPoolProxy).to receive(:connection).and_return(@db_connection)
    allow(Delayed::Backend::ActiveRecord::Job).to receive(:connection).and_return(@dj_connection)
    allow(Delayed::Backend::ActiveRecord::Job::Failed).to receive(:connection).and_return(@dj_connection)
  end

  after(:each) do |example|
    begin
      clear_timers!
      # while disallow_requests! would generally get these, there's a small window
      # between the ajax request starting up and the middleware actually processing it
      wait_for_ajax_requests
      move_mouse_to_known_position
    rescue Selenium::WebDriver::Error::WebDriverError
      # we want to ignore selenium errors when attempting to wait here
    ensure
      SeleniumDriverSetup.disallow_requests!
    end

    if SeleniumDriverSetup.saucelabs_test_run?
      job_id = driver.session_id
      job = SauceWhisk::Jobs.fetch job_id
      old_name = job.name
      job.name = old_name.prepend(example.metadata[:full_description].to_s + " - ")
      job.passed = example.exception.nil?
      job.save

      driver.quit
      SeleniumDriverSetup.reset!
    end
  end

  # logs everything that showed up in the browser console during selenium tests
  after(:each) do |example|
    # safari driver and edge driver do not support driver.manage.logs
    # don't run for sauce labs smoke tests
    next if SeleniumDriverSetup.saucelabs_test_run?

    if example.exception
      html = f('body').attribute('outerHTML')
      document = Nokogiri::HTML(html)
      example.metadata[:page_html] = document.to_html
    end

    browser_logs = driver.manage.logs.get(:browser) rescue nil

    # log INSTUI deprecation warnings
    if browser_logs.present?
      spec_file = example.file_path.sub(/.*spec\/selenium\//, '')
      deprecations =  browser_logs.select {|l| l.message =~ /\[.*deprecated./}.map do |l|
        ">>> #{spec_file}: \"#{example.description}\": #{driver.current_url}: #{l.message.gsub(/.*Warning/, 'Warning') }"
      end
      puts "\n", deprecations.uniq
    end

    if !example.metadata[:ignore_js_errors] && browser_logs.present?
      msg = "browser console logs for \"#{example.description}\":\n" + browser_logs.map(&:message).join("\n\n")
      Rails.logger.info(msg)
      # puts msg

      # if you run into something that doesn't make sense t
      browser_errors_we_dont_care_about = [
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
        "[View] display style is set to 'inline'",
        "Uncaught TypeError: Failed to fetch",
        "Unexpected end of JSON input",
        "The google.com/jsapi JavaScript loader is deprecat",
        "Uncaught Error: Not Found", # for canvas-rce when no backend is set up
        "Uncaught Error: Minified React error #188",
        "Uncaught Error: Minified React error #200", # this is coming from canvas-rce, but we should fix it
        "Access to Font at 'http://cdnjs.cloudflare.com/ajax/libs/mathjax/",
        "Access to XMLHttpRequest at 'http://www.example.com/' from origin",
        "The user aborted a request" # The server doesn't respond fast enough sometimes and requests can be aborted. For example: when a closing a dialog.
      ].freeze

      javascript_errors = browser_logs.select do |e|
        e.level == "SEVERE" &&
          e.message.present? &&
          browser_errors_we_dont_care_about.none? {|s| e.message.include?(s)}
      end

      if javascript_errors.present?
        raise RuntimeError, javascript_errors.map(&:message).join("\n\n")
      end
    end
  end
end
