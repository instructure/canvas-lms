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
include Socket::Constants
require File.expand_path(File.dirname(__FILE__) + '/server')

SELENIUM_CONFIG = Setting.from_config("selenium") || {}
SERVER_IP = UDPSocket.open { |s| s.connect('8.8.8.8', 1); s.addr.last }
SERVER_PORT = SELENIUM_CONFIG[:app_port] || 3002
APP_HOST = "#{SERVER_IP}:#{SERVER_PORT}"
SECONDS_UNTIL_COUNTDOWN = 5
SECONDS_UNTIL_GIVING_UP = 60
MAX_SERVER_START_TIME = 60

module SeleniumTestsHelperMethods
  def setup_selenium
    if !SELENIUM_CONFIG[:host_and_port]
      browser = SELENIUM_CONFIG[:browser].try(:to_sym) || :firefox
      options = {}
      if SELENIUM_CONFIG[:firefox_profile].present? && browser == :firefox
        options[:profile] = Selenium::WebDriver::Firefox::Profile.from_name(SELENIUM_CONFIG[:firefox_profile])
      end
      driver = Selenium::WebDriver.for(browser, options)
    else
      driver = Selenium::WebDriver.for(
        :remote, 
        :url => 'http://' + (SELENIUM_CONFIG[:host_and_port] || "localhost:4444") + '/wd/hub', 
        :desired_capabilities => (SELENIUM_CONFIG[:browser].try(:to_sym) || :firefox)
      )
    end
    driver.get(app_host)
    driver.manage.timeouts.implicit_wait = 3
    driver
  end
  
  def app_host
    "http://#{APP_HOST}"
  end

  def self.wait_for_port(port, tries = 60)
    while tries > 0
      tries -= 1
      socket = Socket.new(AF_INET, SOCK_STREAM, 0)
      sockaddr = Socket.pack_sockaddr_in(port, '0.0.0.0')
      begin
        socket.bind(sockaddr)
        socket.close
        return port
      rescue Errno::EADDRINUSE => e
        sleep 1
      end
    end
    
    raise "The port #{port} is not ready!"
  end

  def self.start_in_process_webrick_server
    wait_for_port(SERVER_PORT)
    
    HostUrl.default_host = APP_HOST
    HostUrl.file_host = APP_HOST
    server = SpecFriendlyWEBrickServer
    app = Rack::Builder.new do
      use Rails::Rack::Debugger unless Rails.env.test?
      map '/' do
        use Rails::Rack::Static
        run ActionController::Dispatcher.new
      end
    end.to_app
    server.run(app, :Port => SERVER_PORT, :AccessLog => [])
    shutdown = lambda do
      server.shutdown
      HostUrl.default_host = nil
      HostUrl.file_host = nil
    end
    at_exit { shutdown.call }
    return shutdown
  end
  
  def self.start_forked_webrick_server
    wait_for_port(SERVER_PORT)
    
    domain_conf_path = File.expand_path(File.dirname(__FILE__) + '/../../config/domain.yml')
    domain_conf = YAML.load_file(domain_conf_path)
    old_domain = domain_conf[Rails.env]["domain"]
    domain_conf[Rails.env]["domain"] = APP_HOST
    File.open(domain_conf_path, 'w') { |f| YAML.dump(domain_conf, f) }
    HostUrl.default_host = APP_HOST
    HostUrl.file_host = APP_HOST
    server_pid = fork do
      base = File.expand_path(File.dirname(__FILE__))
      STDOUT.reopen(File.open("/dev/null", "w"))
      STDERR.reopen(File.open("#{base}/../../log/test-server.log", "a"))
      ENV['SELENIUM_WEBRICK_SERVER'] = '1'
      exec("#{base}/../../script/server", "-p", SERVER_PORT.to_s, "-e", Rails.env)
    end
    closed = false
    shutdown = lambda do
      unless closed
        Process.kill 'KILL', server_pid
        Process.wait server_pid
        domain_conf[Rails.env]["domain"] = old_domain
        File.open(domain_conf_path, 'w') { |f| YAML.dump(domain_conf, f) }
        HostUrl.default_host = nil
        HostUrl.file_host = nil
        closed = true
      end
    end
    at_exit { shutdown.call }
    for i in 0..MAX_SERVER_START_TIME
      s = TCPSocket.open('127.0.0.1', SERVER_PORT) rescue nil
      break if s
      sleep 1
    end
    raise "Failed starting script/server" unless s
    s.close
    return shutdown
  end
end

shared_examples_for "all selenium tests" do

  include SeleniumTestsHelperMethods

  attr_reader :selenium_driver
  alias_method :driver, :selenium_driver
  
  def login_as(username = "nobody@example.com", password = "asdfasdf")
    # log out (just in case)
    driver.navigate.to(app_host + '/logout')
    
    driver.find_element(:css, '#pseudonym_session_unique_id').send_keys username
    password_element = driver.find_element(:css, '#pseudonym_session_password')
    password_element.send_keys(password)
    password_element.submit
  end
  alias_method :login, :login_as

  def wait_for_dom_ready
    driver.execute_script <<-JS
      window.seleniumDOMIsReady = false; 
      $(function(){ 
        window.setTimeout(function(){
          //by doing a setTimeout, we ensure that the execution of all js completes. then we run selenium.
          window.seleniumDOMIsReady = true; 
        }, 1);
      });
    JS
    dom_is_ready = false
    until (dom_is_ready) do
      dom_is_ready = driver.execute_script "return window.seleniumDOMIsReady"
      sleep 1 
    end
  end
  
  def keep_trying
    60.times do |i|
      puts "trying #{SECONDS_UNTIL_GIVING_UP - i}" if i > SECONDS_UNTIL_COUNTDOWN
      if i < SECONDS_UNTIL_GIVING_UP - 2
        val = (yield rescue false)
        break(val) if val
      elsif i == SECONDS_UNTIL_GIVING_UP - 1
        yield
      else
        raise
      end
      sleep 1
    end
  end
  
  def find_with_jquery(selector)
    driver.execute_script("return $('#{selector.gsub(/'/, '\\\\\'')}')[0];")
  end
  
  def find_all_with_jquery(selector)
    driver.execute_script("return $('#{selector.gsub(/'/, '\\\\\'')}').toArray();")
  end
  
  # pass in an Element pointing to the textarea that is tinified.
  def wait_for_tiny(element)
    # TODO: Better to wait for an event from tiny?
    parent = element.find_element(:xpath, '..')
    tiny_frame = nil
    keep_trying {
      begin
        tiny_frame = parent.find_element(:css, 'iframe')
      rescue => e
        puts "#{e.inspect}"
        false
      end
    }
    tiny_frame
  end
  
  def in_frame(id, &block)
    saved_window_handle = driver.window_handle
    driver.switch_to.frame id
    yield
    driver.switch_to.window saved_window_handle
  end
  
  def get(link)
    driver.get(app_host + link)
    wait_for_dom_ready
  end

  self.use_transactional_fixtures = false
  
  append_after(:each) do
    ALL_MODELS.each &:delete_all
  end
  
  append_before(:all) do
    @selenium_driver = setup_selenium
  end

  append_after(:all) do
    @webserver_shutdown.call
    @selenium_driver.quit
  end
 
end

shared_examples_for "in-process server selenium tests" do
  it_should_behave_like "all selenium tests"
  prepend_before(:all) do
    @webserver_shutdown = SeleniumTestsHelperMethods.start_in_process_webrick_server
  end
end

shared_examples_for "forked server selenium tests" do
  it_should_behave_like "all selenium tests"
  prepend_before(:all) do
    @webserver_shutdown = SeleniumTestsHelperMethods.start_forked_webrick_server
  end
end
