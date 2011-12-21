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
include I18nUtilities

SELENIUM_CONFIG = Setting.from_config("selenium") || {}
SERVER_IP = SELENIUM_CONFIG[:server_ip] || UDPSocket.open { |s| s.connect('8.8.8.8', 1); s.addr.last }
SECONDS_UNTIL_COUNTDOWN = 5
SECONDS_UNTIL_GIVING_UP = 20
MAX_SERVER_START_TIME = 60

$server_port = nil
$app_host_and_port = nil

at_exit do
  [1,2,3].each do
    begin
      $selenium_driver.try(:quit)
      break
    rescue Timeout::Error => te
      puts "rescued timeout error from selenium_driver quit : #{te}"
    end
  end
end

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
      if path = SELENIUM_CONFIG[:paths].try(:[], browser)
        Selenium::WebDriver.const_get(browser.to_s.capitalize).path = path
      end
      driver = Selenium::WebDriver.for(browser, options)
    else
      caps = SELENIUM_CONFIG[:browser].try(:to_sym) || :firefox
      if caps == :firefox && SELENIUM_CONFIG[:firefox_profile]
        profile = Selenium::WebDriver::Firefox::Profile.from_name SELENIUM_CONFIG[:firefox_profile]
        caps = Selenium::WebDriver::Remote::Capabilities.firefox(:firefox_profile => profile)
      end

      driver = nil
      [1,2,3].each do |times|
        begin
          driver = Selenium::WebDriver.for(
            :remote,
            :url => 'http://' + (SELENIUM_CONFIG[:host_and_port] || "localhost:4444") + '/wd/hub',
            :desired_capabilities => caps
          )
          break
        rescue Exception => e
          puts "Error attempting to start remote webdriver: #{e}"
          raise e if times == 3
        end
      end

    end
    driver.manage.timeouts.implicit_wait = 1
    driver
  end

  #this is needed for using the before_label function in I18nUtilities
  def t(*a, &b)
    I18n.t(*a, &b)
  end

  def app_host
    "http://#{$app_host_and_port}"
  end

  def self.setup_host_and_port(tries = 60)
    if SELENIUM_CONFIG[:server_port]
      $server_port = SELENIUM_CONFIG[:server_port]
      $app_host_and_port = "#{SERVER_IP}:#{$server_port}"
      return $server_port
    end

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
    domain_conf[Rails.env] ||= {}
    old_domain = domain_conf[Rails.env]["domain"]
    domain_conf[Rails.env]["domain"] = $app_host_and_port
    File.open(domain_conf_path, 'w') { |f| YAML.dump(domain_conf, f) }
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
        s = nil
        Timeout::timeout(5) do
          s = TCPSocket.open('127.0.0.1', $server_port) rescue nil
          break if s
        end
        break if s
      rescue Timeout::Error
        puts "timeout error attempting to connect to forked webrick server"
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

  def selenium_driver; $selenium_driver; end
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
      PseudonymSession.any_instance.stubs(:session_credentials).returns([])
      PseudonymSession.any_instance.stubs(:record).returns { pseudonym.reload }
      PseudonymSession.any_instance.stubs(:used_basic_auth?).returns(false)
      # PseudonymSession.stubs(:find).returns(@pseudonym_session)
    end
  end

  def user_logged_in(opts={})
    user_with_pseudonym({:active_user => true}.merge(opts))
    create_session(@pseudonym, opts[:real_login] || $in_proc_webserver_shutdown.nil?)
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

  def admin_logged_in(opts={})
    account_admin_user({:active_user => true}.merge(opts))
    user_logged_in({:user => @user}.merge(opts))
  end

  def site_admin_logged_in(opts={})
    site_admin_user({:active_user => true}.merge(opts))
    user_logged_in({:user => @user}.merge(opts))
  end

  def expect_new_page_load
    driver.execute_script("INST.still_on_old_page = true;")
    yield
    keep_trying_until { driver.execute_script("return INST.still_on_old_page;") == nil }
    wait_for_dom_ready
  end

  def wait_for_dom_ready
    keep_trying_until(120) { driver.execute_script("return $") != nil }
    driver.execute_script <<-JS
      window.seleniumDOMIsReady = false;
      $(function(){
        window.setTimeout(function(){
          //by doing a setTimeout, we ensure that the execution of all js completes. then we run selenium.
          window.seleniumDOMIsReady = true;
        }, 1);
      });
    JS
    dom_is_ready = driver.execute_script "return window.seleniumDOMIsReady"
    until (dom_is_ready) do
      sleep 0.1
      dom_is_ready = driver.execute_script "return window.seleniumDOMIsReady"
    end
  end

  def wait_for_ajax_requests(wait_start = 0)
    driver.execute_async_script(<<-JS)
      var callback = arguments[arguments.length - 1];
      if (typeof($) == 'undefined') {
        callback(-1);
      } else {
        var waitForAjaxStop = function(value) {
          $(document).bind('ajaxStop.canvasTestAjaxWait', function() {
            $(document).unbind('.canvasTestAjaxWait');
            callback(value);
          });
        }
        if ($.active == 0) {
          // if there are no active requests, wait {wait_start}ms for one to start
          var timeout = window.setTimeout(function() {
            $(document).unbind('.canvasTestAjaxWait');
            callback(0);
          }, #{wait_start});
          $(document).bind('ajaxStart.canvasTestAjaxWait', function() {
            window.clearTimeout(timeout);
            waitForAjaxStop(2);
          });
        } else {
          waitForAjaxStop(1);
        }
      }
    JS
  end

  def wait_for_animations(wait_start = 0)
    driver.execute_async_script(<<-JS)
      var callback = arguments[arguments.length - 1];
      if (typeof($) == 'undefined') {
        callback(-1);
      } else {
        var waitForAnimateStop = function(value) {
          var _stop = $.fx.stop;
          $.fx.stop = function() {
            $.fx.stop = _stop;
            _stop.apply(this, arguments);
            callback(value);
          }
        }
        if ($.timers.length == 0) {
          var _tick = $.fx.tick;
          // wait {wait_start}ms for an animation to start
          var timeout = window.setTimeout(function() {
            $.fx.tick = _tick;
            callback(0);
          }, #{wait_start});
          $.fx.tick = function() {
            window.clearTimeout(timeout);
            $.fx.tick = _tick;
            waitForAnimateStop(2);
            _tick.apply(this, arguments);
          }
        } else {
          waitForAnimateStop(1);
        }
      }
    JS
  end

  def wait_for_ajaximations(wait_start = 0)
    wait_for_ajax_requests(wait_start)
    wait_for_animations(wait_start)
  end

  def keep_trying_until(seconds = SECONDS_UNTIL_GIVING_UP)
    val = false
    seconds.times do |i|
      puts "trying #{seconds - i}" if i > SECONDS_UNTIL_COUNTDOWN
      val = false
      begin
        val = yield
        break if val
      rescue => e
        raise if i == seconds - 1
      end
      sleep 1
    end
    raise "Unexpected #{val.inspect}" unless val
    val
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

  def expect_fired_alert(&block)
    driver.execute_script(<<-JS)
      window.canvasTestSavedAlert = window.alert;
      window.canvasTestAlertFired = false;
      window.alert = function() {
        window.canvasTestAlertFired = true;
        return true;
      }
    JS
    
    yield
    
    keep_trying_until {
      driver.execute_script(<<-JS)
        var value = window.canvasTestAlertFired;
        window.canvasTestAlertFired = false;
        return value;
      JS
    }
    
    driver.execute_script(<<-JS)
      window.alert = window.canvasTestSavedAlert;
    JS
  end

  def in_frame(id, &block)
    saved_window_handle = driver.window_handle
    driver.switch_to.frame id
    yield
    driver.switch_to.window saved_window_handle
  end

  def type_in_tiny(tiny_controlling_element, text)
    scr = "$(#{tiny_controlling_element.to_s.to_json}).editorBox('execute', 'mceInsertContent', false, #{text.to_s.to_json})"
    driver.execute_script(scr)
  end

  def hover_and_click(element_jquery_finder)
    find_with_jquery(element_jquery_finder.to_s).should be_present
    driver.execute_script(%{$(#{element_jquery_finder.to_s.to_json}).trigger('mouseenter').click()})
  end

  def is_checked(selector)
    if selector.is_a?(String)
      return driver.execute_script('return $("'+selector+'").is(":checked")')
    else
      return selector.attribute(:checked) == 'checked'
    end
  end

  def set_value(input, value)
    if input.tag_name == 'select'
      input.find_element(:css, "option[value='#{value}']").click
    else
      replace_content(input, value)
    end
    driver.execute_script(input['onchange']) if input['onchange']
  end

  def find_option_value(selector_type, selector_css, option_text)
    select = driver.find_element(selector_type, selector_css)
    select.click
    options = select.find_elements(:css, 'option')
    option_value = ''
    for option in options
      if option.text == option_text
        option_value = option.attribute('value')
        break
      end
    end
    option_value
  end

  def element_exists(selector_type, selector)
    exists = false
    begin
      driver.find_element(selector_type, selector)
      exists = true
    rescue
    end
    exists
  end

  def datepicker_prev
    datepicker = driver.find_element(:css, '#ui-datepicker-div')
    datepicker.find_element(:css, '.ui-datepicker-prev').click
    find_with_jquery('#ui-datepicker-div a:contains(15)').click
    datepicker
  end

  def datepicker_next
    datepicker = driver.find_element(:css, '#ui-datepicker-div')
    datepicker.find_element(:css, '.ui-datepicker-next').click
    find_with_jquery('#ui-datepicker-div a:contains(15)').click
    datepicker
  end

  def stub_kaltura
    # trick kaltura into being activated
    Kaltura::ClientV3.stubs(:config).returns({
          'domain' => 'www.instructuremedia.com',
          'resource_domain' => 'www.instructuremedia.com',
          'partner_id' => '100',
          'subpartner_id' => '10000',
          'secret_key' => 'fenwl1n23k4123lk4hl321jh4kl321j4kl32j14kl321',
          'user_secret_key' => '1234821hrj3k21hjk4j3kl21j4kl321j4kl3j21kl4j3k2l1',
          'player_ui_conf' => '1',
          'kcw_ui_conf' => '1',
          'upload_ui_conf' => '1'
    })
    kal = mock('Kaltura::ClientV3')
    kal.stubs(:startSession).returns "new_session_id_here"
    Kaltura::ClientV3.stubs(:new).returns(kal)
  end

  def get(link)
    driver.get(app_host + link)
    wait_for_dom_ready
  end

  def refresh_page
    driver.navigate.refresh
    wait_for_dom_ready
  end

  def type_in_tiny(selector, content)
    driver.execute_script("$('#{selector}').editorBox('execute', 'mceInsertContent',false, '#{content}')")
  end

  def make_full_screen
    w, h = driver.execute_script <<-JS
      if (window.screen) {
        return [ window.screen.availWidth, window.screen.availHeight ];
      }
      return [ 0, 0 ];
    JS

    if w > 0 and h > 0
      driver.manage.window.move_to(0, 0)
      driver.manage.window.resize_to(w, h)
    end
  end

  def replace_content(el, value)
    el.clear
    el.send_keys(value)
  end

  def check_image(element)
    require 'open-uri'
    element.should be_displayed
    element.tag_name.should == 'img'
    temp_file = open(element.attribute('src'))
    temp_file.size.should > 0
  end

  def check_file(element)
    require 'open-uri'
    element.should be_displayed
    element.tag_name.should == 'a'
    temp_file = open(element.attribute('href'))
    temp_file.size.should > 0
  end

  def assert_flash_notice_message(okay_message_regex)
    keep_trying_until do
      text = driver.find_element(:css, "#flash_notice_message").text
      raise "server error" if text =~ /The last request didn't work out/
      text =~ okay_message_regex
    end
  end

  self.use_transactional_fixtures = false

  append_after(:each) do
    wait_for_ajax_requests
    ALL_MODELS.each { |m| truncate_table(m) }
  end

  append_before(:each) do
    driver.manage.timeouts.implicit_wait = 1
    driver.manage.timeouts.script_timeout = 60
  end

  append_before(:all) do
    $selenium_driver ||= setup_selenium
  end

  append_before(:all) do
    unless $check_screen_dimensions
      w, h = driver.execute_script <<-JS
        if (window.screen) {
          return [window.screen.availWidth, window.screen.availHeight];
        }
      JS
      raise("desktop dimensions (#{w}x#{h}) are too small to successfully run the selenium specs, minimum size of 1024x760 is required.") unless w >= 1024 && h >= 760
      $check_screen_dimensions = true
    end
  end
end

TEST_FILE_UUIDS = { "testfile1.txt" => "63f46f1c-dd4a-467d-a136-333f262f1366",
                "testfile1copy.txt" => "63f46f1c-dd4a-467d-a136-333f262f1366",
                    "testfile2.txt" => "5d714eca-2cff-4737-8604-45ca098165cc",
                    "testfile3.txt" => "72476b31-58ab-48f5-9548-a50afe2a2fe3",
                    "testfile4.txt" => "38f6efa6-aff0-4832-940e-b6f88a655779",
                    "testfile5.zip" => "3dc43133-840a-46c8-ea17-3e4bef74af37",
                       "graded.png" => File.read(File.dirname(__FILE__) + '/../../public/images/graded.png') }
def get_file(filename)
  data = TEST_FILE_UUIDS[filename]
  @file = Tempfile.new(filename.split(/(?=\.)/))
  @file.write data
  @file.close
  fullpath = @file.path
  filename = File.basename(@file.path)
  if SELENIUM_CONFIG[:host_and_port]
    driver.file_detector = proc do |args|
      args.first if File.exist?(args.first.to_s)
    end
  end
  [filename, fullpath, data, @file]
end

shared_examples_for "in-process server selenium tests" do
  it_should_behave_like "all selenium tests"
  prepend_before(:all) do
    $in_proc_webserver_shutdown ||= SeleniumTestsHelperMethods.start_in_process_webrick_server
  end
  before do
    HostUrl.default_host = $app_host_and_port
    HostUrl.file_host = $app_host_and_port
  end
end

shared_examples_for "forked server selenium tests" do
  it_should_behave_like "all selenium tests"
  prepend_before(:all) do
    $in_proc_webserver_shutdown.try(:call)
    $in_proc_webserver_shutdown = nil
    @forked_webserver_shutdown = SeleniumTestsHelperMethods.start_forked_webrick_server
  end

  append_after(:all) do
    @forked_webserver_shutdown.call
  end
end
