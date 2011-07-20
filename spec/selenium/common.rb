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
require File.expand_path(File.dirname(__FILE__) + '/custom_selenium_rspec_matchers')
require File.expand_path(File.dirname(__FILE__) + '/server')

SELENIUM_CONFIG = Setting.from_config("selenium") || {}
SERVER_IP = UDPSocket.open { |s| s.connect('8.8.8.8', 1); s.addr.last }
SECONDS_UNTIL_COUNTDOWN = 5
SECONDS_UNTIL_GIVING_UP = 60
MAX_SERVER_START_TIME = 60

$server_port = nil
$app_host_and_port = nil

module SeleniumTestsHelperMethods
  def setup_selenium
    if SELENIUM_CONFIG[:host] && SELENIUM_CONFIG[:port] && !SELENIUM_CONFIG[:host_and_port]
      SELENIUM_CONFIG[:host_and_port] = "#{SELENIUM_CONFIG[:host]}:#{SELENIUM_CONFIG[:port]}"
    end
    if !SELENIUM_CONFIG[:host_and_port]
      browser = SELENIUM_CONFIG[:browser].try(:to_sym) || :firefox
      options = {}
      if SELENIUM_CONFIG[:firefox_profile].present? && browser == :firefox
        options[:profile] = Selenium::WebDriver::Firefox::Profile.from_name(SELENIUM_CONFIG[:firefox_profile])
      end
      driver = Selenium::WebDriver.for(browser, options)
    else
      caps = SELENIUM_CONFIG[:browser].try(:to_sym) || :firefox
      if caps == :firefox && SELENIUM_CONFIG[:firefox_profile]
        profile = Selenium::WebDriver::Firefox::Profile.from_name SELENIUM_CONFIG[:firefox_profile]
        caps = Selenium::WebDriver::Remote::Capabilities.firefox(:firefox_profile => profile)
      end
      driver = Selenium::WebDriver.for(
        :remote, 
        :url => 'http://' + (SELENIUM_CONFIG[:host_and_port] || "localhost:4444") + '/wd/hub', 
        :desired_capabilities => caps
      )
    end
    driver.manage.timeouts.implicit_wait = 3
    driver
  end
  
  def app_host
    "http://#{$app_host_and_port}"
  end

  def self.setup_host_and_port(tries = 60)
    tried_ports = Set.new
    while tried_ports.length < 60
      port = rand(65535 - 1024) + 1024
      next if tried_ports.include? port
      tried_ports << port
      
      socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
      socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_REUSEADDR, true)
      sockaddr = Socket.pack_sockaddr_in(port, '0.0.0.0')
      begin
        socket.bind(sockaddr)
        socket.close
        puts "found port #{port} after #{tried_ports.length} tries"
        $server_port = port
        $app_host_and_port = "#{SERVER_IP}:#{$server_port}"
        
        return $server_port
      rescue Errno::EADDRINUSE => e
        # pass
      end
    end
    
    raise "couldn't find an available port after #{tried_ports.length} tries! ports tried: #{tried_ports.join ", "}"
  end


  def self.start_in_process_webrick_server
    setup_host_and_port
    
    HostUrl.default_host = $app_host_and_port
    HostUrl.file_host = $app_host_and_port
    server = SpecFriendlyWEBrickServer
    app = Rack::Builder.new do
      use Rails::Rack::Debugger unless Rails.env.test?
      map '/' do
        use Rails::Rack::Static
        run ActionController::Dispatcher.new
      end
    end.to_app
    server.run(app, :Port => $server_port, :AccessLog => [])
    shutdown = lambda do
      server.shutdown
      HostUrl.default_host = nil
      HostUrl.file_host = nil
    end
    at_exit { shutdown.call }
    return shutdown
  end
  
  def self.start_forked_webrick_server
    setup_host_and_port
    
    domain_conf_path = File.expand_path(File.dirname(__FILE__) + '/../../config/domain.yml')
    domain_conf = YAML.load_file(domain_conf_path)
    old_domain = domain_conf[Rails.env]["domain"]
    domain_conf[Rails.env]["domain"] = $app_host_and_port
    File.open(domain_conf_path, 'w') { |f| YAML.dump(domain_conf, f) }
    HostUrl.default_host = $app_host_and_port
    HostUrl.file_host = $app_host_and_port
    server_pid = fork do
      base = File.expand_path(File.dirname(__FILE__))
      STDOUT.reopen(File.open("/dev/null", "w"))
      STDERR.reopen(File.open("#{base}/../../log/test-server.log", "a"))
      ENV['SELENIUM_WEBRICK_SERVER'] = '1'
      exec("#{base}/../../script/server", "-p", $server_port.to_s, "-e", Rails.env)
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
      begin
        Timeout::timeout(5) do
          s = TCPSocket.open('127.0.0.1', $server_port) rescue nil
          break if s
        end
      rescue Timeout::Error
        # pass
      end
      sleep 1
    end
    raise "Failed starting script/server" unless s
    s.close
    return shutdown
  end
end

shared_examples_for "all selenium tests" do

  include SeleniumTestsHelperMethods
  include CustomSeleniumRspecMatchers

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

  def create_session(pseudonym, real_login)
    if real_login
      login_as(pseudonym.unique_id, pseudonym.password)
    else
      @pseudonym_session = mock(PseudonymSession)
      @pseudonym_session.stub!(:session_credentials).and_return([])
      @pseudonym_session.stub!(:record).and_return { pseudonym.reload }
      PseudonymSession.stub!(:find).and_return(@pseudonym_session)
    end
  end

  def user_logged_in(opts={})
    user_with_pseudonym({:active_user => true}.merge(opts))
    create_session(@pseudonym, opts[:real_login])
  end

  def course_with_teacher_logged_in(opts={})
    user_logged_in(opts)
    course_with_teacher({:user => @user, :active_course => true, :active_enrollment => true}.merge(opts))
  end

  def course_with_student_logged_in(opts={})
    user_logged_in(opts)
    course_with_student({:user => @user, :active_course => true, :active_enrollment => true}.merge(opts))
  end

  def course_with_admin_logged_in(opts={})
    account_admin_user({:active_user => true}.merge(opts))
    user_logged_in({:user => @user}.merge(opts))
    course_with_teacher({:user => @user, :active_course => true, :active_enrollment => true}.merge(opts))
  end

  def expect_new_page_load
    driver.execute_script("INST.still_on_old_page = true;")
    yield
    keep_trying_until { driver.execute_script("return INST.still_on_old_page;") == nil }
    wait_for_dom_ready
  end

  def wait_for_dom_ready
    (driver.execute_script "return $").should_not be_nil
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
  
  def keep_trying_until(seconds = SECONDS_UNTIL_GIVING_UP)
    seconds.times do |i|
      puts "trying #{seconds - i}" if i > SECONDS_UNTIL_COUNTDOWN
      if i < seconds - 2
        val = (yield rescue false)
        break(val) if val
      elsif i == seconds - 1
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
    keep_trying_until {
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
  
  def make_full_screen
    driver.execute_script <<-JS
      if (window.screen) {
        window.moveTo(0, 0);
        window.resizeTo(window.screen.availWidth, window.screen.availHeight);
      }
    JS
  end

  self.use_transactional_fixtures = false

  append_after(:each) do
    ALL_MODELS.each { |m| truncate_table(m) }
  end

  append_before(:all) do
    @selenium_driver = setup_selenium
  end

  append_after(:all) do
    @webserver_shutdown.call
    @selenium_driver.quit
  end

  append_before(:all) do
    unless $check_screen_dimensions
      w, h = driver.execute_script <<-JS
        if (window.screen) {
          return [window.screen.availWidth, window.screen.availHeight];
        }
      JS
      raise("desktop dimensions (#{w}x#{h}) are too small to successfully run the selenium specs, minimum size of 1024x768 is required.") unless w >= 1024 && h >= 768
      $check_screen_dimensions = true
    end
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
