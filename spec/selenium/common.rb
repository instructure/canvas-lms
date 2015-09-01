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
require File.expand_path(File.dirname(__FILE__) + '/test_setup/custom_selenium_rspec_matchers')
require File.expand_path(File.dirname(__FILE__) + '/test_setup/selenium_driver_setup')

Dir[File.dirname(__FILE__) + '/test_setup/common_helper_methods/*.rb'].each {|file| require file }

include I18nUtilities

$selenium_config = ConfigFile.load("selenium") || {}
SERVER_IP = $selenium_config[:server_ip] || UDPSocket.open { |s| s.connect('8.8.8.8', 1); s.addr.last }
BIND_ADDRESS = $selenium_config[:bind_address] || '0.0.0.0'
SECONDS_UNTIL_COUNTDOWN = 5
SECONDS_UNTIL_GIVING_UP = 20
MAX_SERVER_START_TIME = 60

#NEED BETTER variable handling
THIS_ENV = ENV['TEST_ENV_NUMBER'].present? ? ENV['TEST_ENV_NUMBER'].to_i : 1
WEBSERVER = (ENV['WEBSERVER'] || 'thin').freeze

$server_port = nil
$app_host_and_port = nil

at_exit do
  [1, 2, 3].each do
    begin
      $selenium_driver.try(:quit)
      break
    rescue Timeout::Error => te
      puts "rescued timeout error from selenium_driver quit : #{te}"
    end
  end
end

shared_context "in-process server selenium tests" do
  include SeleniumDriverSetup
  include CustomSeleniumRspecMatchers
  include OtherHelperMethods
  include CustomSeleniumActions
  include CustomAlertActions
  include CustomPageLoaders
  include CustomScreenActions
  include CustomValidators
  include CustomWaitMethods
  include LoginAndSessionMethods

  # set up so you can use rails urls helpers in your selenium tests
  include Rails.application.routes.url_helpers

  prepend_before :all do
    SeleniumDriverSetup.allow_requests!
  end

  prepend_before :each do
    SeleniumDriverSetup.allow_requests!
  end

  prepend_before :all do
    $in_proc_webserver_shutdown ||= SeleniumDriverSetup.start_webserver(WEBSERVER)
  end

  append_before :all do
    $selenium_driver ||= setup_selenium
    default_url_options[:host] = $app_host_and_port
    close_modal_if_present
    resize_screen_to_normal
  end

  append_before :each do
    #the driver sometimes gets in a hung state and this if almost always the first line of code to catch it
    begin
      tries ||= 3
      driver.manage.timeouts.implicit_wait = 3
      driver.manage.timeouts.script_timeout = 60
      EncryptedCookieStore.test_secret = SecureRandom.hex(64)
      enable_forgery_protection
    rescue
      if ENV['PARALLEL_EXECS'] != nil
        #cleans up and provisions a new driver
        puts "ERROR: thread: #{THIS_ENV} selenium server hung, attempting to recover the node"
        $selenium_driver = nil
        $selenium_driver ||= setup_selenium
        default_url_options[:host] = $app_host_and_port
        retry unless (tries -= 1).zero?
      else
        raise # preserve original error
      end
    end
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
      methods_to_sync = %w{execute exec_cache exec_no_cache query}
      [@db_connection, @dj_connection].each do |conn|
        methods_to_sync.each do |method_name|
          if conn.respond_to?(method_name, true) && !conn.respond_to?("#{method_name}_with_synchronization", true)
            conn.class.class_eval <<-RUBY
              def #{method_name}_with_synchronization(*args)
                @mutex ||= Mutex.new
                @mutex.synchronize { #{method_name}_without_synchronization(*args) }
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

  after(:each) do
    clear_timers!
    # while disallow_requests! would generally get these, there's a small window
    # between the ajax request starting up and the middleware actually processing it
    begin
      wait_for_ajax_requests
    rescue Selenium::WebDriver::Error::WebDriverError
      # we want to ignore selenium errors when attempting to wait here
      nil
    end
    SeleniumDriverSetup.disallow_requests!
    truncate_all_tables unless self.use_transactional_fixtures
  end
end
