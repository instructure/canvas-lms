require "fileutils"

module SeleniumDriverSetup
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
  module ::Selenium
    module WebDriver
      module Firefox
        class Launcher
          remove_const(:SOCKET_LOCK_TIMEOUT)
        end
      end
    end
  end
  Selenium::WebDriver::Firefox::Launcher::SOCKET_LOCK_TIMEOUT = 90

  # Number of recent specs to show in failure pages
  RECENT_SPEC_RUNS_LIMIT = 500
  # Number of identical failures in a row before we abort this worker
  RECENT_SPEC_FAILURE_LIMIT = 10
  # Number of failures to record
  MAX_FAILURES_TO_RECORD = 20
  IMPLICIT_WAIT_TIMEOUT = 15

  def browser
    $selenium_config[:browser].try(:to_sym) || :firefox
  end

  def setup_selenium
    path = $selenium_config[:paths].try(:[], browser)
    if path
      Selenium::WebDriver.const_get(browser.to_s.capitalize).path = path
    end

    SeleniumDriverSetup.set_up_display_buffer if run_headless?

    failure_proc = -> {
      # ensure we quit frd, cuz it's not going to work (otherwise rspec
      # would keep retrying on subsequent groups/examples)
      RSpec.world.wants_to_quit = true
      raise "unable to initialize webdriver"
    }

    driver = with_retries failure_proc: failure_proc do
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

    focus_viewport driver if run_headless?

    driver.manage.timeouts.implicit_wait = IMPLICIT_WAIT_TIMEOUT
    driver.manage.timeouts.script_timeout = 60

    puts "Browser: #{browser_name(driver)} - #{browser_version(driver)}"

    driver
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

  # prevents subsequent specs from failing because tooltips are showing etc.
  def move_mouse_to_known_position
    driver.mouse.move_to(f("body"), 0, 0) if driver.ready_for_interaction
  end

  def self.set_up_display_buffer
    require "headless"

    test_number = ENV["TEST_ENV_NUMBER"]
    # it'll be '', '2', '3', '4'...
    test_number = test_number.blank? ? 1 : test_number.to_i
    # start at 21 to avoid conflicts with other test runner Xvfb stuff

    display = 20 + test_number
    @headless = Headless.new(
      display: display,
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
      }
    )
    @headless.start
    puts "Setting up DISPLAY=#{ENV['DISPLAY']}"
  end

  def self.headless
    @headless
  end

  def focus_viewport(driver)
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
    begin
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
  end
  module_function :with_retries

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
    caps.version = $selenium_config[:version] unless $selenium_config[:version].nil?
    caps.platform = $selenium_config[:platform] unless $selenium_config[:platform].nil?
    caps["tunnel-identifier"] = $selenium_config[:tunnel_id] unless $selenium_config[:tunnel_id].nil?
    caps[:unexpectedAlertBehaviour] = 'ignore'
    caps
  end

  def selenium_url
    (browser == :chrome) ? $selenium_config[:remote_url_chrome] : $selenium_config[:remote_url_firefox]
  end

  def ruby_firefox_driver
    puts "Thread: provisioning local firefox driver"
    Selenium::WebDriver.for(:firefox,
                            profile: firefox_profile,
                            desired_capabilities: desired_capabilities)
  end

  def selenium_driver
    $selenium_driver ||= setup_selenium
  end

  alias_method :driver, :selenium_driver

  def firefox_profile
    if $selenium_config[:firefox_path].present?
      Selenium::WebDriver::Firefox::Binary.path = "#{$selenium_config[:firefox_path]}"
    end
    profile = Selenium::WebDriver::Firefox::Profile.new
    profile.add_extension Rails.root.join("spec/selenium/test_setup/JSErrorCollector.xpi")
    profile.log_file = "/dev/stdout"
    # firefox randomly reloads if/when it decides to download the OpenH264 codec, so don't let it
    profile["media.gmp-manager.url"] = ""

    if $selenium_config[:firefox_profile].present?
      profile = Selenium::WebDriver::Firefox::Profile.from_name($selenium_config[:firefox_profile])
    end
    profile
  end

  def browser_name(driver)
    driver_capabilities(driver).browser_name
  end

  def browser_version(driver)
    driver_capabilities(driver).version
  end

  def driver_capabilities(driver)
    driver.instance_variable_get(:@bridge)
          .instance_variable_get(:@capabilities)
  end

  def app_host
    "http://#{$app_host_and_port}"
  end

  def self.note_recent_spec_run(example, exception)
    @recent_spec_runs ||= []
    @recent_spec_runs << {
      location: example.metadata[:location],
      exception: exception,
      pending: example.pending
    }
    @recent_spec_runs = @recent_spec_runs.last(RECENT_SPEC_RUNS_LIMIT)

    if ENV["ABORT_ON_CONSISTENT_BADNESS"]
      recent_errors = @recent_spec_runs.last(RECENT_SPEC_FAILURE_LIMIT).map { |run| run[:exception] && run[:exception].to_s }.compact
      if recent_errors.size >= RECENT_SPEC_FAILURE_LIMIT && recent_errors.uniq.size == 1
        $stderr.puts "ERROR: got the same failure #{RECENT_SPEC_FAILURE_LIMIT} times in a row, aborting"
        RSpec.world.wants_to_quit = true
      end
    end
  end

  def self.error_template
    @error_template ||= begin
      layout_path = Rails.root.join("spec/selenium/test_setup/selenium_error.html.erb")
      ActionView::Template::Handlers::Erubis.new(File.read(layout_path))
    end
  end

  def start_capturing_video
    SeleniumDriverSetup.headless.video.start_capture if capture_video?
  end

  def record_errors(example, exception, log_messages)
    js_errors = driver.execute_script("return window.JSErrorCollector_errors && window.JSErrorCollector_errors.pump()") || []

    # ignore "mutating the [[Prototype]] of an object" js errors
    mutating_prototype_error = "mutating the [[Prototype]] of an object"
    js_errors.reject! do |error|
      error["errorMessage"].start_with? mutating_prototype_error
    end

    # always send js errors to stdout, even if the spec passed. we have to
    # empty the JSErrorCollector anyway, so we might as well show it.
    meta = example.metadata
    puts meta[:location] if js_errors.present? || exception
    js_errors.each do |error|
      puts "  JS Error: #{error["errorMessage"]} (#{error["sourceName"]}:#{error["lineNumber"]})"
    end

    SeleniumDriverSetup.number_of_failures ||= 0
    SeleniumDriverSetup.number_of_failures += 1 if exception

    if capture_screenshots? || capture_video?
      if exception
        errors_path = Rails.root.join("log/seleniumfailures")
        FileUtils.mkdir_p(errors_path)

        summary_name = meta[:location].sub(/\A[.\/]+/, "").gsub(/\//, ":")
        include_recordings = SeleniumDriverSetup.number_of_failures <= MAX_FAILURES_TO_RECORD

        if capture_screenshots? && include_recordings
          screenshot_name = summary_name + ".png"
          driver.save_screenshot(errors_path.join(screenshot_name))
        end

        if capture_video?
          if include_recordings
            screen_capture_name = summary_name + ".mp4"
            SeleniumDriverSetup.headless.video.stop_and_save(errors_path.join(screen_capture_name))
          else
            SeleniumDriverSetup.headless.video.stop_and_discard
          end
        end

        recent_spec_runs = SeleniumDriverSetup.recent_spec_runs

        log_message_formatter = EscapeCode::HtmlFormatter.new(log_messages.join("\n"))

        # make a nice little html file for jenkins
        File.open(errors_path.join(summary_name + ".html"), "w") do |file|
          output_buffer = nil # Erubis wants this local var
          file.write SeleniumDriverSetup.error_template.result(binding)
        end

        puts meta[:location]
        if include_recordings
          puts "  Screenshot: #{errors_path.join(screenshot_name)}" if capture_screenshots?
          puts "  Screen capture: #{errors_path.join(screen_capture_name)}" if capture_video?
        else
          puts "  Screenshot skipped because we had more than #{MAX_FAILURES_TO_RECORD} failures" if capture_screenshots?
          puts "  Screen capture skipped because we had more than #{MAX_FAILURES_TO_RECORD} failures" if capture_video?
        end
      else
        SeleniumDriverSetup.headless.video.stop_and_discard if capture_video?
      end
    end
  end

  def self.setup_host_and_port
    ENV['CANVAS_CDN_HOST'] = "canvas.instructure.com"
    if $selenium_config[:server_port]
      $server_port = $selenium_config[:server_port]
      $app_host_and_port = "#{SERVER_IP}:#{$server_port}"
      return $server_port
    end

    # find an available socket
    s = Socket.new(:INET, :STREAM)
    s.setsockopt(:SOCKET, :REUSEADDR, true)
    s.bind(Addrinfo.tcp(SERVER_IP, 0))

    $server_port = s.local_address.ip_port


    server_ip = if $selenium_config[:browser] == 'ie'
                  # makes default URL for selenium the external IP of the box for standalone sel servers
                  `curl http://instance-data/latest/meta-data/public-ipv4` # command for aws boxes gets external ip
                else
                  s.local_address.ip_address
                end

    $app_host_and_port = "#{server_ip}:#{s.local_address.ip_port}"
    puts "found available port: #{$app_host_and_port}"

    return $server_port

  ensure
    s.close() if s
  end

  class ServerStartupError < RuntimeError; end

  def self.start_webserver(webserver)
    with_retries(error_class: ServerStartupError) do
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
  rescue ServerStartupError
    # if this fails, it's before any specs run, so we can bail completely
    # (if we don't, rspec's exit hooks will run/fail all examples in this
    # group, meaning other workers won't pick them up)
    exit! 1
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

  def self.rack_app
    app = Rack::Builder.new do
      use Rails::Rack::Debugger unless Rails.env.test?
      run CanvasRails::Application
    end.to_app

    spec_safe_app = lambda do |env|
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

    lambda do |env|
      log_request = env["REQUEST_URI"] !~ %r{/(javascripts|dist)}
      req = "#{env['REQUEST_METHOD']} #{env['REQUEST_URI']}"
      Rails.logger.info "STARTING REQUEST #{req}" if log_request
      result = spec_safe_app.call(env)
      Rails.logger.info "FINISHED REQUEST #{req}: #{result[0]}" if log_request
      result
    end
  end

  class << self
    attr_reader :recent_spec_runs
    attr_accessor :number_of_failures

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
  end

  def self.start_in_process_thin_server
    require File.expand_path(File.dirname(__FILE__) + '/servers/thin_server')
    server = SpecFriendlyThinServer
    app = self.rack_app
    server.run(app, :BindAddress => BIND_ADDRESS, :Port => $server_port, :AccessLog => [])
    shutdown = self.shutdown_webserver(server)
    return shutdown
  end

  def self.start_in_process_webrick_server
    require File.expand_path(File.dirname(__FILE__) + '/servers/webrick_server')
    server = SpecFriendlyWEBrickServer
    app = self.rack_app
    server.run(app, :BindAddress => BIND_ADDRESS, :Port => $server_port, :AccessLog => [])
    shutdown = self.shutdown_webserver(server)
    return shutdown
  end
end
