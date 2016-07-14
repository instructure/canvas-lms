#
# Copyright (C) 2011 Instructure, Inc.
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
require "selenium-webdriver"
require "socket"
require "timeout"
require 'coffee-script'
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

include I18nUtilities

$selenium_config = ConfigFile.load("selenium") || {}
SERVER_IP = $selenium_config[:server_ip] || UDPSocket.open { |s| s.connect('8.8.8.8', 1); s.addr.last }
BIND_ADDRESS = $selenium_config[:bind_address] || '0.0.0.0'
SECONDS_UNTIL_GIVING_UP = 20
MAX_SERVER_START_TIME = 15

#NEED BETTER variable handling
THIS_ENV = ENV['TEST_ENV_NUMBER'].present? ? ENV['TEST_ENV_NUMBER'].to_i : 1
WEBSERVER = (ENV['WEBSERVER'] || 'thin').freeze

$server_port = nil
$app_host_and_port = nil

at_exit do
  begin
    $selenium_driver.try(:quit)
  rescue Errno::ECONNREFUSED
  end
end

module SeleniumErrorRecovery
  # this gets called wherever an exception happens (example, before/after/around, each/all)
  def set_exception(exception, *args)
    maybe_recover_from_exception(exception)
    super
  end

  def maybe_recover_from_exception(exception)
    case exception
    when Errno::ENOMEM
      # no sense trying anymore, give up and hope that other nodes pick up the slack
      puts "Error: got `#{exception}`, aborting"
      RSpec.world.wants_to_quit = true
    when EOFError, Errno::ECONNREFUSED, Net::ReadTimeout
      if $selenium_driver && !RSpec.world.wants_to_quit && exception.backtrace.grep(/selenium-webdriver/).present?
        puts "SELENIUM: webdriver is misbehaving.  Will try to re-initialize."
        # this will cause the selenium driver to get re-initialized if it
        # crashes for some reason
        $selenium_driver = nil
        return true
      end
    end
    false
  end
end
RSpec::Core::Example.prepend(SeleniumErrorRecovery)

shared_context "in-process server selenium tests" do
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

  # set up so you can use rails urls helpers in your selenium tests
  include Rails.application.routes.url_helpers

  prepend_before :each do
    SeleniumDriverSetup.allow_requests!
    driver.ready_for_interaction = false # need to `get` before we do anything selenium-y in a spec
  end

  prepend_before :all do
    $in_proc_webserver_shutdown ||= SeleniumDriverSetup.start_webserver(WEBSERVER)
  end

  append_before :all do
    retry_count = 0
    begin
      $selenium_driver ||= setup_selenium
      default_url_options[:host] = $app_host_and_port
      close_modal_if_present
      resize_screen_to_normal
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
    HostUrl.stubs(:default_host).returns($app_host_and_port)
    HostUrl.stubs(:file_host).returns($app_host_and_port)
  end

  # tricksy tricksy. grab the current connection, and then always return the same one
  # (even if on a different thread - i.e. the server's thread), so that it will be in
  # the same transaction and see the same data
  before do
    if self.use_transactional_fixtures
      @db_connection = ActiveRecord::Base.connection
      @dj_connection = Delayed::Backend::ActiveRecord::Job.connection

      # synchronize db connection methods for a modicum of thread safety
      methods_to_sync = %w{execute exec_cache exec_no_cache query transaction}
      [@db_connection, @dj_connection].each do |conn|
        methods_to_sync.each do |method_name|
          if conn.respond_to?(method_name, true) && !conn.respond_to?("#{method_name}_with_synchronization", true)
            arg_list = "*args"
            arg_list << ", &Proc.new" if method_name == "transaction"
            conn.class.class_eval <<-RUBY, __FILE__, __LINE__ + 1
              def #{method_name}_with_synchronization(*args)
                SeleniumDriverSetup.request_mutex.synchronize { #{method_name}_without_synchronization(#{arg_list}) }
              end
              alias_method_chain :#{method_name}, :synchronization
            RUBY
          end
        end
      end

      ActiveRecord::ConnectionAdapters::ConnectionPool.any_instance.stubs(:connection).returns(@db_connection)
      Delayed::Backend::ActiveRecord::Job.stubs(:connection).returns(@dj_connection)
      Delayed::Backend::ActiveRecord::Job::Failed.stubs(:connection).returns(@dj_connection)
    end
  end

  around do |example|
    Rails.logger.capture_messages do
      example.run
    end
  end

  before do |example|
    start_capturing_video
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
      exception = $ERROR_INFO || example.exception
      SeleniumDriverSetup.note_recent_spec_run(example, exception)
      record_errors(example, exception, Rails.logger.captured_messages)
      SeleniumDriverSetup.disallow_requests!
      truncate_all_tables unless self.use_transactional_fixtures
    end
  end
end
