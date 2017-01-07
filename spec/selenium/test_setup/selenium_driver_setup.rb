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
  SECONDS_UNTIL_GIVING_UP = 20
  MAX_SERVER_START_TIME = 15

  # Number of recent specs to show in failure pages
  RECENT_SPEC_RUNS_LIMIT = 500
  # Number of identical failures in a row before we abort this worker
  RECENT_SPEC_FAILURE_LIMIT = 10
  # Number of failures to record
  MAX_FAILURES_TO_RECORD = 20
  IMPLICIT_WAIT_TIMEOUT = 15

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

    attr_writer :number_of_failures,
                :recent_spec_runs
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

      @driver.manage.timeouts.implicit_wait = IMPLICIT_WAIT_TIMEOUT
      @driver.manage.timeouts.script_timeout = 60

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

    def capture_screenshots?
      ENV["CAPTURE_SCREENSHOTS"]
    end

    def capture_video?
      capture_screenshots? && run_headless?
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

    def recent_spec_runs
      @recent_spec_runs ||= []
    end

    def number_of_failures
      @number_of_failures ||= 0
    end

    def note_recent_spec_run(example, exception)
      recent_spec_runs << {
        location: example.metadata[:location],
        exception: exception,
        pending: example.pending
      }
      self.recent_spec_runs = recent_spec_runs.last(RECENT_SPEC_RUNS_LIMIT)

      if ENV["ABORT_ON_CONSISTENT_BADNESS"]
        recent_errors = recent_spec_runs.last(RECENT_SPEC_FAILURE_LIMIT).
          map { |run| run[:exception] && run[:exception].to_s }.compact
        if recent_errors.size >= RECENT_SPEC_FAILURE_LIMIT && recent_errors.uniq.size == 1
          $stderr.puts "ERROR: got the same failure #{RECENT_SPEC_FAILURE_LIMIT} times in a row, aborting"
          RSpec.world.wants_to_quit = true
        end
      end
    end

    def error_template
      @error_template ||= begin
        layout_path = Rails.root.join("spec/selenium/test_setup/selenium_error.html.erb")
        ActionView::Template::Handlers::Erubis.new(File.read(layout_path))
      end
    end

    def start_capturing_video
      headless.video.start_capture if capture_video?
    end

    def js_errors
      js_errors = close_modal_if_present do
        driver.execute_script("return window.JSErrorCollector_errors && window.JSErrorCollector_errors.pump()") || []
      end

      # ignore "mutating the [[Prototype]] of an object" js errors
      mutating_prototype_error = "mutating the [[Prototype]] of an object"
      js_errors.reject! do |error|
        error["errorMessage"].start_with? mutating_prototype_error
      end

      js_errors
    end

    def errors_path
      @errors_path ||= begin
        errors_path = Rails.root.join("log/seleniumfailures")
        FileUtils.mkdir_p(errors_path)
        errors_path
      end
    end

    def include_recordings?
      number_of_failures <= MAX_FAILURES_TO_RECORD
    end

    def capture_screenshot(base_name)
      return unless capture_screenshots? && include_recordings?

      screenshot_name = base_name + ".png"
      driver.save_screenshot(errors_path.join(screenshot_name))
      screenshot_name
    end

    def capture_video(base_name)
      return unless capture_video?

      if include_recordings?
        screen_capture_name = base_name + ".mp4"
        headless.video.stop_and_save(errors_path.join(screen_capture_name))
        screen_capture_name
      else
        headless.video.stop_and_discard
        nil
      end
    end

    def prepare_error_data(example, exception, log_messages)
      self.number_of_failures += 1 if exception
      summary_name = example.metadata[:location].sub(/\A[.\/]+/, "").gsub(/\//, ":")
      headless.video.stop_and_discard if capture_video? && !exception

      {
        meta: example.metadata,
        summary_name: summary_name,
        exception: exception,
        log_messages: log_messages,
        js_errors: js_errors,
        screenshot_name: exception && capture_screenshot(summary_name),
        screen_capture_name: exception && capture_video(summary_name)
      }
    end

    def log_spec_errors(data)
      puts data[:meta][:location]

      # always send js errors to stdout, even if the spec passed. we have to
      # empty the JSErrorCollector anyway, so we might as well show it.
      log_js_errors data[:js_errors]

      return unless data[:exception] && (capture_screenshots? || capture_video?)

      if include_recordings?
        puts "  Screenshot: #{errors_path.join(data[:screenshot_name])}" if capture_screenshots?
        puts "  Screen capture: #{errors_path.join(data[:screen_capture_name])}" if capture_video?
      else
        puts "  Screenshot skipped because we had more than #{MAX_FAILURES_TO_RECORD} failures" if capture_screenshots?
        puts "  Screen capture skipped because we had more than #{MAX_FAILURES_TO_RECORD} failures" if capture_video?
      end
    end

    def log_js_errors(errors)
      errors.each do |error|
        puts "  JS Error: #{error['errorMessage']} (#{error['sourceName']}:#{error['lineNumber']})"
      end
    end

    def create_spec_error_page(data)
      log_message_formatter = EscapeCode::HtmlFormatter.new(data[:log_messages].join("\n"))

      # make a nice little html file for jenkins
      File.open(errors_path.join(data[:summary_name] + ".html"), "w") do |file|
        output_buffer = nil # Erubis wants this local var
        file.write error_template.result(binding)
      end
    end

    def record_errors(example, exception, log_messages)
      error_data = prepare_error_data(example, exception, log_messages)

      log_spec_errors error_data if error_data[:exception] || error_data[:js_errors].present?
      create_spec_error_page error_data if error_data[:exception]
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

      lambda do |env|
        log_request = env["REQUEST_URI"] !~ %r{/(javascripts|dist)}
        req = "#{env['REQUEST_METHOD']} #{env['REQUEST_URI']}"
        Rails.logger.info "STARTING REQUEST #{req}" if log_request
        result = app.call(env)
        Rails.logger.info "FINISHED REQUEST #{req}: #{result[0]}" if log_request
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
