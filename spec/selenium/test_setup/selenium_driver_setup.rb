require "fileutils"
require_relative "common_helper_methods/custom_alert_actions"

# WebDriver uses port 7054 (the "locking port") as a mutex to ensure
# that we don't launch two Firefox instances at the same time. Each
# new instance you create will wait for the mutex before starting
# the browser, then release it as soon as the browser is open.
#
# The default port mutex wait timeout is 45 seconds.
# Bump it to 90 seconds as a stopgap for the recent flood of:
# `unable to bind to locking port 7054 within 45 seconds`
#
# TODO: Investigate why it's taking so long to launch Firefox, or
#       what process is hogging port 7054.
Selenium::WebDriver::Firefox::Launcher.send :remove_const, :SOCKET_LOCK_TIMEOUT
Selenium::WebDriver::Firefox::Launcher::SOCKET_LOCK_TIMEOUT = 90

module SeleniumDriverSetup
  CONFIG = ConfigFile.load("selenium") || {}.freeze
  SECONDS_UNTIL_GIVING_UP = 10
  MAX_SERVER_START_TIME = 5
  IMPLICIT_WAIT_TIMEOUT = 5
  SCRIPT_TIMEOUT = 5

  def driver
    SeleniumDriverSetup.driver
  end

  def app_host_and_port
    SeleniumDriverSetup.app_host_and_port
  end

  def app_url
    "http://#{app_host_and_port}"
  end

  # prevents subsequent specs from failing because tooltips are showing etc.
  def move_mouse_to_known_position
    driver.mouse.move_to(f("body"), 0, 0) if driver.ready_for_interaction
  end

  class ServerStartupError < RuntimeError; end

  class << self
    include CustomAlertActions
    extend Forwardable

    attr_accessor :browser_log,
                  :browser_process,
                  :headless,
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
          Thread.new { start_driver }
        ].each(&:join)
      rescue StandardError
        puts "selenium startup failed: #{$ERROR_INFO}"
        puts "exiting :'("
        # if either one fails, it's before any specs run, so we can bail
        # completely (if we don't, rspec's exit hooks will run/fail all
        # examples in this group, meaning other workers won't pick them
        # up).
        #
        # the custom exit code is so that test-queue can detect and allow
        # a certain percentage of bad workers, while the build as a whole
        # can still succeed
        exit! 98
      end

      at_exit { shutdown }
    end

    def shutdown
      server.shutdown if server
      if driver
        driver.close
        driver.quit
      end
    rescue StandardError
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

      set_up_display_buffer if run_headless?

      @driver = create_driver

      focus_viewport if run_headless?

      @driver.manage.timeouts.implicit_wait = 0 # nothing should wait by default
      SeleniumExtensions::FinderWaiting.timeout = IMPLICIT_WAIT_TIMEOUT # except finding elements
      @driver.manage.timeouts.script_timeout = SCRIPT_TIMEOUT

      puts "Browser: #{browser_name} - #{browser_version}"

      @driver
    end

    def webdriver_failure_proc
      -> do
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

    def run_headless?
      ENV.key?("TEST_ENV_NUMBER")
    end

    HEADLESS_DEFAULTS = {
      dimensions: "1920x1080x24",
      reuse: false,
      destroy_at_exit: true,
      video: {
        provider: :ffmpeg,
        # yay interframe compression
        codec: 'libx264',
        # use less CPU. doesn't actually shrink the resulting file much.
        frame_rate: 4,
        extra: [
          # quicktime doesn't understand the default yuv422p
          '-pix_fmt', 'yuv420p',
          # limit videos to 1 minute 20 seconds in case something bad happens and we forget to stop recording
          '-t', '80',
          # use less CPU
          '-preset', 'superfast'
        ]
      }.freeze
    }.freeze

    def set_up_display_buffer
      # start_driver can get called again if firefox dies, but
      # self.headless should already be good to go
      return if headless

      require "headless"

      test_number = ENV["TEST_ENV_NUMBER"]
      # it'll be '', '2', '3', '4'...
      test_number = test_number.blank? ? 1 : test_number.to_i
      # start at 21 to avoid conflicts with other test runner Xvfb stuff
      display = 20 + test_number

      self.headless = Headless.new(HEADLESS_DEFAULTS.merge({
        display: display
      }))
      headless.start
      puts "Setting up DISPLAY=#{ENV['DISPLAY']}"
    end

    def focus_viewport
      # force the viewport to have focus right away; otherwise certain specs
      # will fail unless they follow another dialog accepting/dismissing spec,
      # since they rely on focus/blur events, which don't fire if the window
      # doesn't have focus
      driver.execute_script "alert('yolo')"
      driver.switch_to.alert.accept
    end

    def ie_driver
      puts "using IE driver"
      selenium_remote_driver
    end

    def safari_driver
      puts "using safari driver"
      selenium_remote_driver
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
      Oj.default_options = {:escape_mode => :json}
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
        $stderr.puts "Giving up"
        failure_proc ? failure_proc.call : raise
      else
        sleep delay
        retry
      end
    end

    def ruby_chrome_driver
      puts "Thread: provisioning local chrome driver"
      Selenium::WebDriver.for :chrome, switches: %w[--disable-impl-side-painting]
    end

    def selenium_remote_driver
      puts "Thread: provisioning remote #{browser} driver"
      Selenium::WebDriver.for(
        :remote,
        :url => selenium_url,
        :desired_capabilities => desired_capabilities
      )
    end

    def desired_capabilities
      caps = Selenium::WebDriver::Remote::Capabilities.send(browser)
      caps.version = CONFIG[:version] unless CONFIG[:version].nil?
      caps.platform = CONFIG[:platform] unless CONFIG[:platform].nil?
      caps["tunnel-identifier"] = CONFIG[:tunnel_id] unless CONFIG[:tunnel_id].nil?
      caps[:unexpectedAlertBehaviour] = 'ignore'
      caps
    end

    def selenium_url
      case browser
      when :firefox
        CONFIG[:remote_url_firefox]
      when :chrome
        CONFIG[:remote_url_chrome]
      when :internet_explorer, :safari
        CONFIG[:remote_url]
      else
        raise "unsupported browser #{browser}"
      end
    end

    def ruby_firefox_driver
      puts "Thread: provisioning local firefox driver"
      Selenium::WebDriver.for(:firefox,
                              profile: firefox_profile,
                              desired_capabilities: desired_capabilities)
    end

    def firefox_profile
      if CONFIG[:firefox_path].present?
        Selenium::WebDriver::Firefox::Binary.path = "#{CONFIG[:firefox_path]}"
      end
      profile = Selenium::WebDriver::Firefox::Profile.new
      profile.add_extension Rails.root.join("spec/selenium/test_setup/JSErrorCollector.xpi")
      profile.log_file = "/dev/stdout"
      # firefox randomly reloads if/when it decides to download the OpenH264 codec, so don't let it
      profile["media.gmp-manager.url"] = ""

      if CONFIG[:firefox_profile].present?
        profile = Selenium::WebDriver::Firefox::Profile.from_name(CONFIG[:firefox_profile])
      end
      profile
    end

    def_delegator :driver_capabilities, :browser_name

    def browser_version
      driver_capabilities.version
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
      server_ip = UDPSocket.open { |s| s.connect('8.8.8.8', 1) && s.addr.last }
      s = Socket.new(:INET, :STREAM)
      s.setsockopt(:SOCKET, :REUSEADDR, true)
      s.bind(Addrinfo.tcp(server_ip, 0))

      self.server_port = s.local_address.ip_port
      self.server_ip = s.local_address.ip_address
      if CONFIG[:browser] == 'ie'
        # makes default URL for selenium the external IP of the box for standalone sel servers
        self.server_ip = `curl http://instance-data/latest/meta-data/public-ipv4`
      end

      puts "found available port: #{app_host_and_port}"

    ensure
      s.close() if s
    end

    def start_webserver
      ENV['CANVAS_CDN_HOST'] = "canvas.instructure.com"

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

    def spec_safe_rack_app
      app = base_rack_app

      lambda do |env|
        nope = [503, {}, [""]]
        return nope unless allow_requests?

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
      asset_path = %r{\A/(dist|fonts|images|javascripts|optimized|webpack-dist|webpack-dist-optimized)/.*\.[a-z0-9]+\z}

      lambda do |env|
        # make legit asset 404s return more quickly
        asset_request = env["REQUEST_URI"] =~ asset_path
        return [404, {}, [""]] if asset_request && !File.exist?("public/#{env["REQUEST_URI"]}")

        req = "#{env['REQUEST_METHOD']} #{env['REQUEST_URI']}"
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
      request_mutex.synchronize { }
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
      require File.expand_path(File.dirname(__FILE__) + '/servers/thin_server')
      self.server = SpecFriendlyThinServer
      server.run(rack_app, port: server_port)
    end
  end
end

# get some extra verbose logging from firefox for when things go wrong
Selenium::WebDriver::Firefox::Binary.class_eval do
  def execute(*extra_args)
    args = [self.class.path, '-no-remote'] + extra_args
    SeleniumDriverSetup.browser_process = @process = ChildProcess.build(*args)
    SeleniumDriverSetup.browser_log = @process.io.stdout = @process.io.stderr = Tempfile.new("firefox")
    $DEBUG = true
    @process.start
    $DEBUG = nil
  end
end


# make Wait play nicely with Timecop
module Selenium::WebDriver::Wait::Time
  def self.now
    ::Time.now_without_mock_time
  end
end
