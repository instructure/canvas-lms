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
require File.expand_path(File.dirname(__FILE__) + '/helpers/custom_selenium_rspec_matchers')
include I18nUtilities

SELENIUM_CONFIG = ConfigFile.load("selenium") || {}
SERVER_IP = SELENIUM_CONFIG[:server_ip] || UDPSocket.open { |s| s.connect('8.8.8.8', 1); s.addr.last }
BIND_ADDRESS = SELENIUM_CONFIG[:bind_address] || '0.0.0.0'
SECONDS_UNTIL_COUNTDOWN = 5
SECONDS_UNTIL_GIVING_UP = 20
MAX_SERVER_START_TIME = 60

#NEED BETTER variable handling
THIS_ENV = ENV['TEST_ENV_NUMBER'].to_i
THIS_ENV = 1 if ENV['TEST_ENV_NUMBER'].blank?
ENV['WEBSERVER'].nil? ? WEBSERVER = 'webrick' : WEBSERVER = ENV['WEBSERVER']
#set WEBSERVER ENV to webrick to change webserver

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

module SeleniumTestsHelperMethods
  def setup_selenium

    browser = SELENIUM_CONFIG[:browser].try(:to_sym) || :firefox
    host_and_port

    if path = SELENIUM_CONFIG[:paths].try(:[], browser)
      Selenium::WebDriver.const_get(browser.to_s.capitalize).path = path
    end

    driver = if browser == :firefox
               firefox_driver
             elsif browser == :chrome
               chrome_driver
             elsif browser == :ie
               ie_driver
             end

    driver.manage.timeouts.implicit_wait = 3
    driver
  end

  def ie_driver
    require 'testingbot'
    require 'testingbot/tunnel'

    puts "using IE driver"

    caps = Selenium::WebDriver::Remote::Capabilities.ie
    caps.version = "10"
    caps.platform = :WINDOWS
    caps[:unexpectedAlertBehaviour] = 'ignore'

    Selenium::WebDriver.for(
        :remote,
        :url => "http://#{SELENIUM_CONFIG[:testingbot_key]}:#{SELENIUM_CONFIG[:testingbot_secret]}@hub.testingbot.com:4444/wd/hub",
        :desired_capabilities => caps)

  end

  def firefox_driver
    puts "using FIREFOX driver"
    profile = firefox_profile
    caps = Selenium::WebDriver::Remote::Capabilities.firefox(:unexpectedAlertBehaviour => 'ignore')

    if SELENIUM_CONFIG[:host_and_port]
      caps.firefox_profile = profile
      stand_alone_server_firefox_driver(caps)
    else
      ruby_firefox_driver(profile: profile, desired_capabilities: caps)
    end
  end

  def chrome_driver
    puts "using CHROME driver"
    if SELENIUM_CONFIG[:host_and_port]
      stand_alone_server_chrome_driver
    else
      ruby_chrome_driver
    end
  end

  def ruby_chrome_driver
    driver = nil
    begin
      tries ||= 3
      puts "Thread: provisioning selenium chrome ruby driver"
      driver = Selenium::WebDriver.for :chrome
    rescue Exception => e
      puts "Thread #{THIS_ENV}\n try ##{tries}\nError attempting to start remote webdriver: #{e}"
      sleep 2
      retry unless (tries -= 1).zero?
    end
    driver
  end

  def stand_alone_server_chrome_driver
    driver = nil
    3.times do |times|
      begin
        driver = Selenium::WebDriver.for(
            :remote,
            :url => 'http://' + (SELENIUM_CONFIG[:host_and_port] || "localhost:4444") + '/wd/hub',
            :desired_capabilities => :chrome
        )
        break
      rescue Exception => e
        puts "Error attempting to start remote webdriver: #{e}"
        raise e if times == 2
      end
    end
    driver
  end

  def ruby_firefox_driver(options)
    driver = nil
    begin
      tries ||= 3
      puts "Thread: provisioning selenium ruby firefox driver"
      driver = Selenium::WebDriver.for(:firefox, options)
    rescue Exception => e
      puts "Thread #{THIS_ENV}\n try ##{tries}\nError attempting to start remote webdriver: #{e}"
      sleep 2
      retry unless (tries -= 1).zero?
    end
    driver
  end

  def stand_alone_server_firefox_driver(caps)
    driver = nil
    3.times do |times|
      begin
        driver = Selenium::WebDriver.for(
            :remote,
            :url => 'http://' + (SELENIUM_CONFIG[:host_and_port] || "localhost:4444") + '/wd/hub',
            :desired_capabilities => caps
        )
        break
      rescue Exception => e
        puts "Error attempting to start remote webdriver: #{e}"
        raise e if times == 2
      end
    end
    driver
  end

  def firefox_profile
    profile = Selenium::WebDriver::Firefox::Profile.new
    profile.load_no_focus_lib=(true)
    profile.native_events = true

    if SELENIUM_CONFIG[:firefox_profile].present?
      profile = Selenium::WebDriver::Firefox::Profile.from_name(SELENIUM_CONFIG[:firefox_profile])
    end
    profile
  end

  def host_and_port
    if SELENIUM_CONFIG[:host] && SELENIUM_CONFIG[:port] && !SELENIUM_CONFIG[:host_and_port]
      SELENIUM_CONFIG[:host_and_port] = "#{SELENIUM_CONFIG[:host]}:#{SELENIUM_CONFIG[:port]}"
    end
  end

  def set_native_events(setting)
    driver.instance_variable_get(:@bridge).instance_variable_get(:@capabilities).instance_variable_set(:@native_events, setting)
  end


# f means "find" this is a shortcut to finding elements
  def f(selector, scope = nil)
    begin
      (scope || driver).find_element :css, selector
    rescue
      nil
    end
  end

  # short for find with link
  def fln(link_text, scope = nil)
    begin
      (scope || driver).find_element :link, link_text
    rescue
      nil
    end
  end

  # short for find with jquery
  def fj(selector, scope = nil)
    begin
      find_with_jquery selector, scope
    rescue
      nil
    end
  end

# same as `f` except tries to find several elements instead of one
  def ff(selector, scope = nil)
    begin
      (scope || driver).find_elements :css, selector
    rescue
      []
    end
  end

# same as find with jquery but tries to find several elements instead of one
  def ffj(selector, scope = nil)
    begin
      find_all_with_jquery selector, scope
    rescue
      []
    end
  end

#this is needed for using the before_label function in I18nUtilities
  def t(*a, &b)
    I18n.t(*a, &b)
  end

  def app_host
    "http://#{$app_host_and_port}"
  end

  def self.setup_host_and_port(tries = 60)
    ENV['CANVAS_CDN_HOST'] = "canvas.instructure.com"
    if SELENIUM_CONFIG[:server_port]
      $server_port = SELENIUM_CONFIG[:server_port]
      $app_host_and_port = "#{SERVER_IP}:#{$server_port}"
      return $server_port
    end

    # find an available socket
    s = Socket.new(:INET, :STREAM)
    s.setsockopt(:SOCKET, :REUSEADDR, true)
    s.bind(Addrinfo.tcp(SERVER_IP, 0))

    $server_port = s.local_address.ip_port


    server_ip = if SELENIUM_CONFIG[:browser] == 'ie'
                  ##makes default URL for selenium the external IP of the box for standalone sel servers
                  `curl http://instance-data/latest/meta-data/public-ipv4` ##command for aws boxes gets external ip
                else
                  s.local_address.ip_address
                end

    $app_host_and_port = "#{server_ip}:#{s.local_address.ip_port}"
    puts "found available port: #{$app_host_and_port}"

    return $server_port

  ensure
    s.close() if s
  end

  def self.start_webserver(webserver)
    setup_host_and_port
    case webserver
      when 'thin'
        self.start_in_process_thin_server
      when 'webrick'
        self.start_in_process_webrick_server
      else
        puts "no web server specified, defaulting to WEBrick"
        self.start_in_process_webrick_server
    end
  end

  def self.shutdown_webserver(server)
    shutdown = lambda do
      server.shutdown
      HostUrl.default_host = nil
      HostUrl.file_host = nil
    end
    at_exit { shutdown.call }
    return shutdown
  end

  def self.rack_app()
    app = Rack::Builder.new do
      use Rails::Rack::Debugger unless Rails.env.test?
      run CanvasRails::Application
    end.to_app

    lambda do |env|
      nope = [503, {}, [""]]
      return nope unless allow_requests?

      # wrap request in a mutex so we can ensure it doesn't span spec
      # boundaries (see clear_requests!)
      result = request_mutex.synchronize { app.call(env) }

      # check if the spec just finished while we ran, and if so prevent
      # side effects like redirects (and thus moar requests)
      if allow_requests?
        result
      else
        # make sure we clean up the body of requests we throw away
        # https://github.com/rack/rack/issues/658#issuecomment-38476120
        result.last.close if result.last.respond_to?(:close)
        nope
      end
    end
  end

  class << self
    def disallow_requests!
      # ensure the current in-flight request (if any, AJAX or otherwise)
      # finishes up its work, and prevent any subsequent requests before the
      # next spec gets underway. otherwise race conditions can cause sadness
      # with our shared conn and transactional fixtures (e.g. special
      # accounts and their caching)
      @allow_requests = false
      request_mutex.synchronize { }
    end

    def allow_requests!
      @allow_requests = true
    end

    def allow_requests?
      @allow_requests
    end

    def request_mutex
      @request_mutex ||= Mutex.new
    end
  end

  def self.start_in_process_thin_server
    require File.expand_path(File.dirname(__FILE__) + '/../../spec/selenium/servers/thin_server')
    server = SpecFriendlyThinServer
    app = self.rack_app
    server.run(app, :BindAddress => BIND_ADDRESS, :Port => $server_port, :AccessLog => [])
    shutdown = self.shutdown_webserver(server)
    return shutdown
  end

  def self.start_in_process_webrick_server
    require File.expand_path(File.dirname(__FILE__) + '/../../spec/selenium/servers/webrick_server')
    server = SpecFriendlyWEBrickServer
    app = self.rack_app
    server.run(app, :BindAddress => BIND_ADDRESS, :Port => $server_port, :AccessLog => [])
    shutdown = self.shutdown_webserver(server)
    return shutdown
  end

  def exec_cs(script, *args)
    driver.execute_script(CoffeeScript.compile(script), *args)
  end

# a varable named `callback` is injected into your function for you, just call it to signal you are done.
  def exec_async_cs(script, *args)
    to_compile = "var callback = arguments[arguments.length - 1]; #{CoffeeScript.compile(script)}"
    driver.execute_async_script(script, *args)
  end

# usage
# require_exec 'compiled/util/foo', 'bar', <<-CS
#   foo('something')
#   # optionally I should be able to do
#   bar 'something else', ->
#     "stuff"
#     callback('i made it')
#
# CS
#
# simple usage
# require_exec 'i18n!messages', 'i18n.t("foobar")'
  def require_exec(*args)
    code = args.last
    things_to_require = {}
    args[0...-1].each do |file_path|
      things_to_require[file_path] = file_path.split('/').last.split('!').first
    end

    # make sure the code you pass is at least as intented as it should be
    code = code.gsub(/^/, '          ')
    coffee_source = <<-CS
      _callback = arguments[arguments.length - 1];
      cancelCallback = false

      callback = ->
        _callback.apply(this, arguments)
        cancelCallback = true

      require #{things_to_require.keys.to_json}, (#{things_to_require.values.join(', ')}) ->
        res = do ->
#{code}
        _callback(res) unless cancelCallback
    CS
    # make it `bare` because selenium already wraps it in a function and we need to get
    # the arguments for our callback
    js = CoffeeScript.compile(coffee_source, :bare => true)
    driver.execute_async_script(js)
  end

  # add some JS translations to the current page; they'll be merged in at
  # the root level, so the top-most key should be the locale, e.g.
  #
  #   set_translations fr: {key: "Bonjour"}
  def set_translations(translations)
    add_translations = "$.extend(true, I18n, {translations: #{translations.to_json}});"
    if ENV['USE_OPTIMIZED_JS']
      driver.execute_script <<-JS
        define('translations/test', ['i18nObj', 'jquery'], function(I18n, $) {
          #{add_translations}
        });
      JS
    else
      driver.execute_script add_translations
    end
  end
end

shared_examples_for "all selenium tests" do

  include SeleniumTestsHelperMethods
  include CustomSeleniumRspecMatchers

  # set up so you can use rails urls helpers in your selenium tests
  include Rails.application.routes.url_helpers

  def selenium_driver;
    $selenium_driver
  end

  alias_method :driver, :selenium_driver

  def fill_in_login_form(username, password)
    user_element = f('#pseudonym_session_unique_id')
    user_element.send_keys(username)
    password_element = f('#pseudonym_session_password')
    password_element.send_keys(password)
    password_element.submit
  end

  def login_as(username = "nobody@example.com", password = "asdfasdf", expect_success = true)
    destroy_session(true)
    driver.navigate.to(app_host + '/login')
    if expect_success
      expect_new_page_load { fill_in_login_form(username, password) }
      expect(f('#identity .logout')).to be_present
    else
      fill_in_login_form(username, password)
    end
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

  def destroy_session(real_login)
    if real_login
      logout_link = f('#identity .logout a')
      if logout_link
        if logout_link.displayed?
          expect_new_page_load(:accept_alert) { logout_link.click() }
        else
          get '/'
          destroy_session(true)
        end
      end
    else
      PseudonymSession.any_instance.unstub :session_credentials
      PseudonymSession.any_instance.unstub :record
      PseudonymSession.any_instance.unstub :used_basic_auth?
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

  def course_with_observer_logged_in(opts={})
    user_logged_in(opts)
    course_with_observer({:user => @user, :active_course => true, :active_enrollment => true}.merge(opts))
  end

  def course_with_ta_logged_in(opts={})
    user_logged_in(opts)
    course_with_ta({:user => @user, :active_course => true, :active_enrollment => true}.merge(opts))
  end

  def course_with_designer_logged_in(opts={})
    user_logged_in(opts)
    course_with_designer({:user => @user, :active_course => true, :active_enrollment => true}.merge(opts))
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

  def enter_student_view(opts={})
    course = opts[:course] || @course || course(opts)
    get "/courses/#{@course.id}/settings"
    driver.execute_script("$('.student_view_button').click()")
    wait_for_ajaximations
  end

  def expect_new_page_load(accept_alert = false)
    driver.execute_script("INST.still_on_old_page = true;")
    yield
    keep_trying_until do
      begin
        driver.execute_script("return INST.still_on_old_page;") == nil
      rescue Selenium::WebDriver::Error::UnhandledAlertError
        raise unless accept_alert
        driver.switch_to.alert.accept
      end
    end
    wait_for_ajaximations
  end

  def check_domready
    dom_is_ready = driver.execute_script "return window.seleniumDOMIsReady"
    requirejs_resources_loaded = driver.execute_script "return !requirejs.s.contexts._.defQueue.length"
    dom_is_ready and requirejs_resources_loaded
  end

  ##
  # waits for JavaScript to evaluate, occasionally when you click an element
  # a bunch of JS needs to run, this basically puts the rest of your test later
  # in the JS thread
  def wait_for_js
    driver.execute_script <<-JS
      window.selenium_wait_for_js = false;
      setTimeout(function() { window.selenium_wait_for_js = true; });
    JS
    keep_trying_until { driver.execute_script('return window.selenium_wait_for_js') == true }
  end

  def wait_for_dom_ready
    driver.execute_async_script(<<-JS)
     var callback = arguments[arguments.length - 1];
     var pollForJqueryAndRequire = function(){
        if (window.jQuery && window.require && !window.requirejs.s.contexts._.defQueue.length) {
          jQuery(function(){
            setTimeout(callback, 1);
          });
        } else {
          setTimeout(pollForJqueryAndRequire, 1);
        }
      }
      pollForJqueryAndRequire();
    JS
  end

  def wait_for_ajax_requests(wait_start = 0)
    result = driver.execute_async_script(<<-JS)
      var callback = arguments[arguments.length - 1];
      if (window.wait_for_ajax_requests_hit_fallback) {
        callback(0);
      } else if (typeof($) == 'undefined') {
        callback(-1);
      } else {
        var fallbackCallback = window.setTimeout(function() {
          // technically, we should cancel the other timeouts that we've set up at this
          // point, but we're going to be raising an exception anyway when this happens,
          // so it's not a big deal.
          window.wait_for_ajax_requests_hit_fallback = 1;
          callback(-2);
        }, 55000);
        var doCallback = function(value) {
          window.clearTimeout(fallbackCallback);
          callback(value);
        }
        var waitForAjaxStop = function(value) {
          $(document).bind('ajaxStop.canvasTestAjaxWait', function() {
            $(document).unbind('.canvasTestAjaxWait');
            doCallback(value);
          });
        }
        if ($.active == 0) {
          // if there are no active requests, wait {wait_start}ms for one to start
          var timeout = window.setTimeout(function() {
            $(document).unbind('.canvasTestAjaxWait');
            doCallback(0);
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
    if result == -2
      raise "Timed out waiting for ajax requests to finish. (This might mean there was a js error in an ajax callback.)"
    end
    wait_for_js
    result
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
    wait_for_js
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
      rescue Exception => e
        raise if i == seconds - 1
      end
      sleep 1
    end
    raise "Unexpected #{val.inspect}" unless val
    val
  end

  def find_with_jquery(selector, scope = nil)
    driver.execute_script("return $(arguments[0], arguments[1] && $(arguments[1]))[0];", selector, scope)
  end

  def find_all_with_jquery(selector, scope = nil)
    driver.execute_script("return $(arguments[0], arguments[1] && $(arguments[1])).toArray();", selector, scope)
  end

  #pass full selector ex. "#blah td tr" the attibute ex. "style" type and the value ex. "Red"
  def fba(selector, attrib, value)
    f("#{selector} [#{attrib}='#{value}']").click
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

  def dismiss_alert
    keep_trying_until do
      alert = driver.switch_to.alert
      alert.dismiss
      true
    end
  end

  def accept_alert
    keep_trying_until do
      alert = driver.switch_to.alert
      alert.accept
      true
    end
  end

  def in_frame(id, &block)
    saved_window_handle = driver.window_handle
    driver.switch_to.frame(id)
    yield
  ensure
    driver.switch_to.window saved_window_handle
  end

  def type_in_tiny(tiny_controlling_element, text)
    scr = "$(#{tiny_controlling_element.to_s.to_json}).editorBox('execute', 'mceInsertContent', false, #{text.to_s.to_json})"
    driver.execute_script(scr)
  end

  def hover_and_click(element_jquery_finder)
    expect(fj(element_jquery_finder.to_s)).to be_present
    driver.execute_script(%{$(#{element_jquery_finder.to_s.to_json}).trigger('mouseenter').click()})
  end

  def is_checked(css_selector)
    driver.execute_script('return $("'+css_selector+'").prop("checked")')
  end

  def get_value(selector)
    driver.execute_script("return $(#{selector.inspect}).val()")
  end

  def set_value(input, value)
    case input.tag_name
      when 'select'
        input.find_element(:css, "option[value='#{value}']").click
      when 'input'
        case input.attribute(:type)
          when 'checkbox'
            input.click if (!input.selected? && value) || (input.selected? && !value)
          else
            replace_content(input, value)
        end
      else
        replace_content(input, value)
    end
    driver.execute_script(input['onchange']) if input['onchange']
  end

  def get_options(selector, scope=nil)
    Selenium::WebDriver::Support::Select.new(f(selector, scope)).options
  end

  def click_option(select_css, option_text, select_by = :text)
    element = fj(select_css)
    select = Selenium::WebDriver::Support::Select.new(element)
    select.select_by(select_by, option_text)
  end

  def close_visible_dialog
    visible_dialog_element = fj('.ui-dialog:visible')
    visible_dialog_element.find_element(:css, '.ui-dialog-titlebar-close').click
    expect(visible_dialog_element).not_to be_displayed
  end

  def element_exists(css_selector)
    !ffj(css_selector).empty?
  end

  def first_selected_option(select_element)
    select = Selenium::WebDriver::Support::Select.new(select_element)
    option = select.first_selected_option
    option
  end

  def datepicker_prev(day_text = '15')
    datepicker = f('#ui-datepicker-div')
    datepicker.find_element(:css, '.ui-datepicker-prev').click
    fj("#ui-datepicker-div a:contains(#{day_text})").click
    datepicker
  end

  def datepicker_next(day_text = '15')
    datepicker = f('#ui-datepicker-div')
    datepicker.find_element(:css, '.ui-datepicker-next').click
    fj("#ui-datepicker-div a:contains(#{day_text})").click
    datepicker
  end

  def datepicker_current(day_text = '15')
    fj("#ui-datepicker-div a:contains(#{day_text})").click
  end

  def stub_kaltura
    # trick kaltura into being activated
    CanvasKaltura::ClientV3.stubs(:config).returns({
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
    kal = mock('CanvasKaltura::ClientV3')
    kal.stubs(:startSession).returns "new_session_id_here"
    CanvasKaltura::ClientV3.stubs(:new).returns(kal)
  end

  def page_view(opts={})
    course = opts[:course] || @course
    user = opts[:user] || @student
    controller = opts[:controller] || 'assignments'
    summarized = opts[:summarized] || nil
    url = opts[:url]
    user_agent = opts[:user_agent] || 'firefox'

    page_view = course.page_views.build(
        :user => user,
        :controller => controller,
        :url => url,
        :user_agent => user_agent)

    page_view.summarized = summarized
    page_view.request_id = SecureRandom.hex(10)
    page_view.created_at = opts[:created_at] || Time.now

    if opts[:participated]
      page_view.participated = true
      access = page_view.build_asset_user_access
      access.display_name = 'Some Asset'
    end

    page_view.store
    page_view
  end

  # you can pass an array to use the rails polymorphic_path helper, example:
  # get [@course, @announcement] => "http://10.0.101.75:65137/courses/1/announcements/1"
  def get(link, waitforajaximations=true)
    link = polymorphic_path(link) if link.is_a? Array
    driver.get(app_host + link)
    #handles any modals prompted by navigating from the current page
    close_modal_if_present
    wait_for_ajaximations if waitforajaximations
  end

  def close_modal_if_present
    driver.title # if an alert is present, this will trigger the error below
  rescue Selenium::WebDriver::Error::UnhandledAlertError
    driver.switch_to.alert.accept
  end

  def refresh_page
    expect_new_page_load { driver.navigate.refresh }
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

  def resize_screen_to_normal
    w, h = driver.execute_script <<-JS
        if (window.screen) {
          return [window.screen.availWidth, window.screen.availHeight];
        }
    JS
    if w != 1200 || h != 600
      driver.manage.window.move_to(0, 0)
      driver.manage.window.resize_to(1200, 600)
    end
  end

  def resize_screen_to_default
    h = driver.execute_script <<-JS
      if (window.screen) {
        return window.screen.availHeight;
      }
    return 0;
    JS
    if h > 0
      driver.manage.window.move_to(0, 0)
      driver.manage.window.resize_to(1024, h)
    end
  end

  def replace_content(el, value)
    el.clear
    el.send_keys(value)
  end

  # can pass in either an element or a forms css
  def submit_form(form)
    submit_button_css = 'button[type="submit"]'
    button = form.is_a?(Selenium::WebDriver::Element) ? form.find_element(:css, submit_button_css) : f("#{form} #{submit_button_css}")
    # the button may have been hidden via fixDialogButtons
    if !button.displayed? && dialog = dialog_for(button)
      submit_dialog(dialog)
    else
      button.click
    end
  end

  def submit_dialog(dialog, submit_button_css = ".ui-dialog-buttonpane .button_type_submit")
    dialog = f(dialog) unless dialog.is_a?(Selenium::WebDriver::Element)
    dialog = dialog_for(dialog)
    dialog.find_elements(:css, submit_button_css).last.click
  end

  def dialog_for(node)
    node.find_element(:xpath, "ancestor-or-self::div[contains(@class, 'ui-dialog')]") rescue false
  end

  def check_image(element)
    require 'open-uri'
    expect(element).to be_displayed
    expect(element.tag_name).to eq 'img'
    temp_file = open(element.attribute('src'))
    expect(temp_file.size).to be > 0
  end

  def check_element_attrs(element, attrs)
    expect(element).to be_displayed
    attrs.each do |k, v|
      if v.is_a? Regexp
        expect(element.attribute(k)).to match v
      else
        expect(element.attribute(k)).to eq v
      end
    end
  end

  def check_file(element)
    require 'open-uri'
    expect(element).to be_displayed
    expect(element.tag_name).to eq 'a'
    temp_file = open(element.attribute('href'))
    expect(temp_file.size).to be > 0
    temp_file
  end

  def flash_message_present?(type=:warning, message_regex=nil)
    messages = ff("#flash_message_holder .ic-flash-#{type.to_s}")
    return false if messages.length == 0
    if message_regex
      text = messages.map(&:text).join('\n')
      return !!text.match(message_regex)
    end
    return true
  end

  def assert_flash_notice_message(okay_message_regex)
    keep_trying_until { flash_message_present?(:success, okay_message_regex) }
  end

  def assert_flash_warning_message(warn_message_regex)
    keep_trying_until { flash_message_present?(:warning, warn_message_regex) }
  end

  def assert_flash_error_message(fail_message_regex)
    keep_trying_until { flash_message_present?(:error, fail_message_regex) }
  end

  def assert_error_box(selector)
    box = driver.execute_script <<-JS, selector
      var $result = $(arguments[0]).data('associated_error_box');
      return $result ? $result.toArray() : []
    JS
    expect(box.length).to eq 1
    expect(box[0]).to be_displayed
  end

##
# load the simulate plugin to simulate a drag events (among other things)
# will only load it once even if its called multiple times
  def load_simulate_js
    @load_simulate_js ||= begin
      js = File.read('spec/selenium/helpers/jquery.simulate.js')
      driver.execute_script js
    end
  end

# when selenium fails you, reach for .simulate
# takes a CSS selector for jQuery to find the element you want to drag
# and then the change in x and y you want to drag
  def drag_with_js(selector, x, y)
    load_simulate_js
    driver.execute_script "$('#{selector}').simulate('drag', { dx: #{x}, dy: #{y} })"
    wait_for_js
  end

##
# drags an element matching css selector `source_selector` onto an element
# matching css selector `target_selector`
#
# sometimes seleniums drag and drop just doesn't seem to work right this
# seems to be more reliable
  def js_drag_and_drop(source_selector, target_selector)
    source = f source_selector
    source_location = source.location

    target = f target_selector
    target_location = target.location

    dx = target_location.x - source_location.x
    dy = target_location.y - source_location.y

    drag_with_js source_selector, dx, dy
  end

  ##
  # drags the source element to the target element and waits for ajaximations
  def drag_and_drop_element(source, target)
    driver.action.drag_and_drop(source, target).perform
    wait_for_ajaximations
  end

##
# returns true if a form validation error message is visible, false otherwise
  def error_displayed?
    # after it fades out, it's still visible, just off the screen
    driver.execute_script("return $('.error_text:visible').filter(function(){ return $(this).offset().left >= 0 }).length > 0")
  end

  unless EncryptedCookieStore.respond_to?(:test_secret)
    EncryptedCookieStore.class_eval do
      cattr_accessor :test_secret

      def call_with_test_secret(env)
        @secret = self.class.test_secret
        @encryption_key = unhex(@secret)
        call_without_test_secret(env)
      end

      alias_method_chain :call, :test_secret
    end
  end

  append_before (:each) do
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

  append_before (:all) do
    $selenium_driver ||= setup_selenium
    default_url_options[:host] = $app_host_and_port
    close_modal_if_present
    resize_screen_to_normal
  end

  prepend_before :all do
    SeleniumTestsHelperMethods.allow_requests!
  end

  prepend_before :each do
    SeleniumTestsHelperMethods.allow_requests!
  end

  after(:each) do
    clear_timers!
    begin # while disallow_requests! would generally get these, there's a small window between the ajax request starting up and the middleware actually processing it
      wait_for_ajax_requests
    rescue Selenium::WebDriver::Error::WebDriverError
      # we want to ignore selenium errors when attempting to wait here
    end
    SeleniumTestsHelperMethods.disallow_requests!
    truncate_all_tables unless self.use_transactional_fixtures
  end

  def clear_timers!
    # we don't want any AJAX requests getting kicked off after a test ends.
    # the unload event won't fire until sometime after the next test begins (and
    # the old session cookie becomes invalid). that means a late AJAX call can
    # screw up the next test, i.e. two requests send the old (now-invalid)
    # encrypted session cookie, each gets a new (different) session cookie in
    # the response, meaning the authenticity token on your new page might
    # already be invalid.
    driver.execute_script <<-JS
      var highest = setTimeout(function(){}, 1000);
      for (var i = 0; i < highest; i++) {
        clearTimeout(i);
      }
      highest = setInterval(function(){}, 1000);
      for (var i = 0; i < highest; i++) {
        clearInterval(i);
      }
    JS
  end

end

TEST_FILE_UUIDS = {
    "testfile1.txt" => "63f46f1c-dd4a-467d-a136-333f262f1366",
    "testfile1copy.txt" => "63f46f1c-dd4a-467d-a136-333f262f1366",
    "testfile2.txt" => "5d714eca-2cff-4737-8604-45ca098165cc",
    "testfile3.txt" => "72476b31-58ab-48f5-9548-a50afe2a2fe3",
    "testfile4.txt" => "38f6efa6-aff0-4832-940e-b6f88a655779",
    "testfile5.zip" => "3dc43133-840a-46c8-ea17-3e4bef74af37",
    "attachments.zip" => File.read(File.dirname(__FILE__) + "/../fixtures/attachments.zip"),
    "graded.png" => File.read(File.dirname(__FILE__) + '/../../public/images/graded.png'),
    "cc_full_test.zip" => File.read(File.dirname(__FILE__) + '/../fixtures/migration/cc_full_test.zip'),
    "cc_ark_test.zip" => File.read(File.dirname(__FILE__) + '/../fixtures/migration/cc_ark_test.zip'),
    "canvas_cc_minimum.zip" => File.read(File.dirname(__FILE__) + '/../fixtures/migration/canvas_cc_minimum.zip'),
    "canvas_cc_only_questions.zip" => File.read(File.dirname(__FILE__) + '/../fixtures/migration/canvas_cc_only_questions.zip'),
    "qti.zip" => File.read(File.dirname(__FILE__) + '/../fixtures/migration/package_identifier/qti.zip'),
    "a_file.txt" => File.read(File.dirname(__FILE__) + '/../fixtures/files/a_file.txt'),
    "b_file.txt" => File.read(File.dirname(__FILE__) + '/../fixtures/files/b_file.txt'),
    "c_file.txt" => File.read(File.dirname(__FILE__) + '/../fixtures/files/c_file.txt'),
    "amazing_file.txt" => File.read(File.dirname(__FILE__) + '/../fixtures/files/amazing_file.txt'),
    "Dog_file.txt" => File.read(File.dirname(__FILE__) + '/../fixtures/files/Dog_file.txt')
}

def get_file(filename, data = nil)
  data ||= TEST_FILE_UUIDS[filename]
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

def validate_breadcrumb_link(link_element, breadcrumb_text)
  expect_new_page_load { link_element.click }
  if breadcrumb_text != nil
    breadcrumb = f('#breadcrumbs')
    expect(breadcrumb).to include_text(breadcrumb_text)
  end
  expect(driver.execute_script("return INST.errorCount;")).to eq 0
end

def skip_if_ie(additional_error_text)
  skip("skipping test, fails in IE : " + additional_error_text) if driver.browser == :internet_explorer
end

def alert_present?
  is_present = true
  begin
    driver.switch_to.alert
  rescue Selenium::WebDriver::Error::NoAlertPresentError
    is_present = false
  end
  is_present
end

def scroll_page_to_top
  driver.execute_script("window.scrollTo(0, 0")
end

def scroll_page_to_bottom
  driver.execute_script("window.scrollTo(0, document.body.scrollHeight)")
end

# for when you have something like a textarea's value and you want to match it's contents
# against a css selector.
# usage:
# find_css_in_string(some_textarea[:value], '.some_selector').should_not be_empty
def find_css_in_string(string_of_html, css_selector)
  driver.execute_script("return $('<div />').append('#{string_of_html}').find('#{css_selector}')")
end

shared_examples_for "in-process server selenium tests" do
  include_examples "all selenium tests"
  prepend_before (:all) do
    $in_proc_webserver_shutdown ||= SeleniumTestsHelperMethods.start_webserver(WEBSERVER)
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
end
