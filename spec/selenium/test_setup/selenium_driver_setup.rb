# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative "common_helper_methods/custom_alert_actions"
require_relative "common_helper_methods/custom_screen_actions"
require_relative "patches/selenium/webdriver/remote/w3c/bridge"

module SeleniumDriverSetup
  CONFIG = ConfigFile.load("selenium") || {}.freeze
  SECONDS_UNTIL_GIVING_UP = 10
  MAX_SERVER_START_TIME = 5

  TIMEOUTS = {
    # nothing should wait by default
    implicit_wait: 0,
    # except finding elements
    finder: CONFIG[:finder_timeout_seconds] || 5,
    script: CONFIG[:script_timeout_seconds] || 5,
  }.freeze

  # If you have some really slow UI, you can temporarily override
  # the various TIMEOUTs above. use this sparingly -- fix the UI
  # instead :P
  def with_timeouts(timeouts)
    SeleniumDriverSetup.set_timeouts(timeouts)
    yield
  ensure
    SeleniumDriverSetup.set_timeouts(TIMEOUTS.slice(*timeouts.keys))
  end

  def driver
    SeleniumDriverSetup.driver
  end

  def app_host_and_port
    SeleniumDriverSetup.app_host_and_port
  end

  def app_url
    "http://#{app_host_and_port}"
  end

  class ServerStartupError < RuntimeError; end

  class << self
    include CustomScreenActions
    include CustomAlertActions
    extend Forwardable

    attr_accessor :browser_log,
                  :browser_process,
                  :server,
                  :server_ip,
                  :server_port

    def reset!
      dump_browser_log if browser_log
      @driver = nil
    end

    def run
      begin
        [
          Thread.new { start_webserver },
          Thread.new { start_driver },
        ].each(&:join)
      rescue Selenium::WebDriver::Error::WebDriverError
      rescue
        puts "selenium startup failed: #{$ERROR_INFO}"
        puts "exiting :'("
        # if either one fails, it's before any specs run, so we can bail
        # completely (if we don't, rspec's exit hooks will run/fail all
        # examples in this group, meaning other workers won't pick them
        # up).
        #
        exit! 98
      end

      at_exit { shutdown }
    end

    def shutdown
      server&.shutdown
      driver&.quit
    rescue
      nil
    end

    def browser
      CONFIG[:browser].try(:to_sym) || :firefox
    end

    def driver
      @driver || start_driver
    end

    def start_driver
      path = CONFIG[:paths].try(:[], browser)
      if path
        Selenium::WebDriver.const_get(browser.to_s.capitalize).path = path
      end

      @driver = create_driver

      set_timeouts(TIMEOUTS)

      puts "Browser: #{browser_name} - #{browser_version}"

      @driver
    end

    def timeouts
      @timeouts ||= {}
    end

    def set_timeouts(timeouts)
      self.timeouts.merge!(timeouts)
      timeouts.each do |key, value|
        case key
        when :implicit_wait
          @driver.manage.timeouts.implicit_wait = value
        when :finder
          SeleniumExtensions::FinderWaiting.timeout = value
        when :script
          @driver.manage.timeouts.script_timeout = value
        end
      end
    end

    def webdriver_failure_proc
      lambda do
        # ensure we quit frd, cuz it's not going to work (otherwise rspec
        # would keep retrying on subsequent groups/examples)
        RSpec.world.wants_to_quit = true
        raise "unable to initialize webdriver"
      end
    end

    def create_driver
      with_retries failure_proc: webdriver_failure_proc do
        case browser
        when :firefox
          firefox_driver
        when :chrome
          chrome_driver
        when :internet_explorer
          ie_driver
        when :edge
          edge_driver
        when :safari
          safari_driver
        else
          raise "unsupported browser #{browser}"
        end
      end
    end

    def dump_browser_log
      # give browser a moment to wrap up stuff
      sleep 2

      if browser_process.exited?
        puts "#{browser} exited with #{browser_process.exit_code}"
      else
        puts "#{browser} is still running, killing it"
        browser_process.stop
      end

      puts "#{browser} log:"
      browser_log.rewind
      puts browser_log.read
    end

    def ie_driver
      puts "using IE driver"
      selenium_remote_driver
    end

    def edge_driver
      puts "using Edge driver"
      selenium_url ? selenium_remote_driver : ruby_edge_driver
    end

    def safari_driver
      puts "using safari driver"
      selenium_url ? selenium_remote_driver : ruby_safari_driver
    end

    def firefox_driver
      puts "using FIREFOX driver"
      with_vanilla_json do
        selenium_url ? selenium_remote_driver : ruby_firefox_driver
      end
    end

    # oj's xss_safe escapes forward slashes, which makes paths invalid
    # in the firefox profile, which makes log_file asplode
    # see https://github.com/SeleniumHQ/selenium/issues/2435#issuecomment-245458210
    def with_vanilla_json
      orig_options = Oj.default_options
      Oj.default_options = { escape_mode: :json }
      yield
    ensure
      Oj.default_options = orig_options
    end

    def chrome_driver
      puts "using CHROME driver"
      selenium_url ? selenium_remote_driver : ruby_chrome_driver
    end

    def with_retries(how_many: 3, delay: 1, error_class: StandardError, failure_proc: nil)
      tries ||= 0
      yield
    rescue error_class => e
      puts "Attempt #{tries += 1} got error: #{e}"
      if tries >= how_many
        warn "Giving up"
        failure_proc ? failure_proc.call : raise
      else
        sleep delay
        retry
      end
    end

    def ruby_chrome_driver
      puts "Thread: provisioning local chrome driver"
      Selenium::WebDriver.for :chrome, options: desired_capabilities
    end

    def ruby_safari_driver
      puts "Thread: provisioning local safari driver"
      Selenium::WebDriver.for :safari
    end

    def ruby_edge_driver
      puts "Thread: provisioning local edge driver"
      Selenium::WebDriver.for :edge, capabilities: desired_capabilities
    end

    def selenium_remote_driver
      puts "Thread: provisioning remote #{browser} driver"
      puts "Selenium_Url: #{selenium_url}"
      driver = Selenium::WebDriver.for(
        :remote,
        url: selenium_url,
        capabilities: desired_capabilities
      )

      driver.file_detector = lambda do |args|
        # args => ["/path/to/file"]
        str = args.first.to_s
        str if File.exist?(str)
      end

      driver
    end

    def desired_capabilities
      case browser
      when :firefox
        options = Selenium::WebDriver::Options.firefox
        options.log_level = :debug
      when :chrome
        options = Selenium::WebDriver::Options.chrome
        options.browser_version = CONFIG[:browser_version] if CONFIG[:browser_version]
        options.args << "no-sandbox"
        options.args << "start-maximized"
        options.args << "disable-dev-shm-usage"
        if ENV["DISABLE_CORS"]
          options.args << "disable-web-security"
        end
        options.logging_prefs = {
          browser: "ALL",
        }
        # put `auto_open_devtools: true` in your selenium.yml if you want to have
        # the chrome dev tools open by default by selenium
        if CONFIG[:auto_open_devtools]
          options.add_argument("auto-open-devtools-for-tabs")
        end
        # put `headless: true` and `window_size: "<x>,<y>"` in your selenium.yml
        # if you want to run against headless chrome
        if CONFIG[:headless]
          options.add_argument("headless")
        end
      when :edge
        options = Selenium::WebDriver::Options.edge
        options.add_argument("disable-dev-shm-usage")
      when :safari
        # TODO: options for safari driver
      else
        raise "unsupported browser #{browser}"
      end
      options.unhandled_prompt_behavior = "ignore"
      options
    end

    def selenium_url
      case browser
      when :firefox
        CONFIG[:remote_url_firefox] || CONFIG[:remote_url]
      when :chrome
        CONFIG[:remote_url_chrome] || CONFIG[:remote_url]
      when :edge
        CONFIG[:remote_url_edge] || CONFIG[:remote_url]
      when :internet_explorer, :safari
        CONFIG[:remote_url]
      else
        raise "unsupported browser #{browser}"
      end
    end

    def ruby_firefox_driver
      puts "Thread: provisioning local firefox driver"
      Selenium::WebDriver.for(:firefox,
                              options: desired_capabilities)
    end

    def browser_name
      driver.capabilities[:browser_name]
    end

    def browser_version
      driver.capabilities[:browser_version]
    end

    def driver_capabilities
      driver.instance_variable_get(:@bridge)
            .instance_variable_get(:@capabilities)
    end

    def js_errors
      close_modal_if_present do
        driver.execute_script("return window.JSErrorCollector_errors && window.JSErrorCollector_errors.pump()") || []
      end
    end

    def app_host_and_port
      "#{server_ip}:#{server_port}"
    end

    def set_up_host_and_port
      server_ip = UDPSocket.open { |s| s.connect("8.8.8.8", 1) && s.addr.last }
      s = Socket.new(:INET, :STREAM)
      s.setsockopt(:SOCKET, :REUSEADDR, true)
      s.bind(Addrinfo.tcp(server_ip, 0))

      self.server_port = s.local_address.ip_port
      self.server_ip = s.local_address.ip_address
      if CONFIG[:browser] == "ie"
        # makes default URL for selenium the external IP of the box for standalone sel servers
        self.server_ip = `curl http://instance-data/latest/meta-data/public-ipv4`
      end

      puts "found available port: #{app_host_and_port}"
    ensure
      s&.close()
    end

    def start_webserver
      ENV["CANVAS_CDN_HOST"] = "canvas.instructure.com"

      with_retries(error_class: ServerStartupError) do
        set_up_host_and_port
        start_in_process_thin_server
      end
    end

    def base_rack_app
      Rack::Builder.new do
        use Rails::Rack::Debugger unless Rails.env.test?
        run CanvasRails::Application
      end.to_app
    end

    ASSET_PATH = %r{\A/(dist|fonts|images|javascripts)/.*\.[a-z0-9]+\z}

    def asset_request?(url)
      url =~ ASSET_PATH
    end

    def spec_safe_rack_app
      app = base_rack_app

      lambda do |env|
        nope = [503, {}, [""]]
        return nope unless allow_requests?

        return app.call(env) if asset_request?(env["REQUEST_URI"])

        # wrap request in a mutex so we can ensure it doesn't span spec
        # boundaries (see clear_requests!). we also use this mutex to
        # synchronize db access (so both threads see stuff in the overall
        # spec transaction, while ensuring savepoints in one don't mess
        # up the other)
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

    def rack_app
      app = spec_safe_rack_app

      lambda do |env|
        # make legit asset 404s return more quickly
        asset_request = asset_request?(env["REQUEST_URI"])
        return [404, {}, [""]] if asset_request && !File.exist?("public/#{env["REQUEST_URI"]}")

        req = "#{env["REQUEST_METHOD"]} #{env["REQUEST_URI"]}"
        Rails.logger.info "STARTING REQUEST #{req}" unless asset_request
        result = app.call(env)
        Rails.logger.info "FINISHED REQUEST #{req}: #{result[0]}" unless asset_request
        result
      end
    end

    def disallow_requests!
      # ensure the current in-flight request (if any, AJAX or otherwise)
      # finishes up its work, and prevent any subsequent requests before the
      # next spec gets underway. otherwise race conditions can cause sadness
      # with our shared conn and transactional fixtures (e.g. special
      # accounts and their caching)
      @allow_requests = false
      request_mutex.synchronize { nil }
    end

    def allow_requests!
      @allow_requests = true
    end

    def allow_requests?
      @allow_requests != false
    end

    def request_mutex
      @request_mutex ||= Monitor.new
    end

    def start_in_process_thin_server
      require_relative "spec_friendly_web_server"
      self.server = SpecFriendlyWebServer
      server.run(rack_app, port: server_port)
    end
  end
end

# make Wait play nicely with Timecop
module Selenium::WebDriver::Wait::Time
  def self.now
    ::Time.now_without_mock_time
  end
end
