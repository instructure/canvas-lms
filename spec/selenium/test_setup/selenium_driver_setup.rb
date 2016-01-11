require "fileutils"

module SeleniumDriverSetup
  def setup_selenium

    browser = $selenium_config[:browser].try(:to_sym) || :firefox
    host_and_port

    path = $selenium_config[:paths].try(:[], browser)
    if path
      Selenium::WebDriver.const_get(browser.to_s.capitalize).path = path
    end

    run_headless = ENV.key?("TEST_ENV_NUMBER")
    set_up_display_buffer if run_headless

    driver = if browser == :firefox
               firefox_driver
             elsif browser == :chrome
               chrome_driver
             elsif browser == :ie
               ie_driver
             end

    focus_viewport driver if run_headless

    driver.manage.timeouts.implicit_wait = 3
    driver.manage.timeouts.script_timeout = 60

    driver
  end

  def set_up_display_buffer
    require "headless"

    test_number = ENV["TEST_ENV_NUMBER"]
    # it'll be '', '2', '3', '4'...
    test_number = test_number.blank? ? 1 : test_number.to_i
    # start at 21 to avoid conflicts with other test runner Xvfb stuff

    display = 20 + test_number
    Headless.new(display: display, dimensions: "2000x2000x24").start
    puts "Setting up DISPLAY=#{ENV['DISPLAY']}"
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
    require 'testingbot'
    require 'testingbot/tunnel'

    puts "using IE driver"

    caps = Selenium::WebDriver::Remote::Capabilities.ie
    caps.version = "10"
    caps.platform = :WINDOWS
    caps[:unexpectedAlertBehaviour] = 'ignore'

    Selenium::WebDriver.for(
      :remote,
      :url => "http://#{$selenium_config[:testingbot_key]}:" +
                "#{$selenium_config[:testingbot_secret]}@hub.testingbot.com:4444/wd/hub",
      :desired_capabilities => caps)

  end

  def firefox_driver
    puts "using FIREFOX driver"
    profile = firefox_profile
    caps = Selenium::WebDriver::Remote::Capabilities.firefox(:unexpectedAlertBehaviour => 'ignore')

    if $selenium_config[:host_and_port]
      caps.firefox_profile = profile
      stand_alone_server_firefox_driver(caps)
    else
      ruby_firefox_driver(profile: profile, desired_capabilities: caps)
    end
  end

  def chrome_driver
    puts "using CHROME driver"
    if $selenium_config[:host_and_port]
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
    rescue StandardError => e
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
          :url => 'http://' + ($selenium_config[:host_and_port] || "localhost:4444") + '/wd/hub',
          :desired_capabilities => :chrome
        )
        break
      rescue StandardError => e
        puts "Error attempting to start remote webdriver: #{e}"
        raise e if times == 2
      end
    end
    driver
  end

  def ruby_firefox_driver(options)
    try ||= 1
    puts "Thread: provisioning selenium ruby firefox driver (#{options.inspect})"
    # dup is necessary for retries because selenium deletes out of the options
    # TODO: we could try a random port here instead of relying on the default for retries
    # (or killing firefox may be the best move)
    driver = Selenium::WebDriver.for(:firefox, options.dup)
  rescue StandardError => e
    puts <<-ERROR
    Thread #{THIS_ENV}
     try ##{try}
    Error attempting to start remote webdriver: #{e}
    ERROR

    # according to https://code.google.com/p/selenium/issues/detail?id=6760,
    # this could maybe be fixed by killing stale firefoxes?
    system("ps aux")

    if try <= 3
      try += 1
      sleep 2
      retry
    else
      puts "GIVING UP"
      raise
    end
  end

  def stand_alone_server_firefox_driver(caps)
    driver = nil
    3.times do |times|
      begin
        driver = Selenium::WebDriver.for(
          :remote,
          :url => 'http://' + ($selenium_config[:host_and_port] || "localhost:4444") + '/wd/hub',
          :desired_capabilities => caps
        )
        break
      rescue StandardError => e
        puts "Error attempting to start remote webdriver: #{e}"
        raise e if times == 2
      end
    end
    driver
  end

  def selenium_driver
    $selenium_driver ||= setup_selenium
  end

  alias_method :driver, :selenium_driver

  def firefox_profile
    profile = Selenium::WebDriver::Firefox::Profile.new
    profile.add_extension Rails.root.join("spec/selenium/test_setup/JSErrorCollector.xpi")

    if $selenium_config[:firefox_profile].present?
      profile = Selenium::WebDriver::Firefox::Profile.from_name($selenium_config[:firefox_profile])
    end
    profile
  end

  def host_and_port
    if $selenium_config[:host] && $selenium_config[:port] && !$selenium_config[:host_and_port]
      $selenium_config[:host_and_port] = "#{$selenium_config[:host]}:#{$selenium_config[:port]}"
    end
  end

  def set_native_events(setting)
    driver.instance_variable_get(:@bridge).instance_variable_get(:@capabilities).instance_variable_set(:@native_events, setting)
  end

  def app_host
    "http://#{$app_host_and_port}"
  end

  def self.error_template
    @error_template ||= begin
      layout_path = Rails.root.join("spec/selenium/test_setup/selenium_error.html.erb")
      ActionView::Template::Handlers::Erubis.new(File.read(layout_path))
    end
  end

  def record_errors(example)
    js_errors = driver.execute_script("return window.JSErrorCollector_errors && window.JSErrorCollector_errors.pump()") || []
    return unless js_errors.present? || example.exception

    # always send js errors to stdout, even if the spec passed. we have to
    # empty the JSErrorCollector anyway, so we might as well show it.
    meta = example.metadata
    puts meta[:location]
    js_errors.each do |error|
      puts "  JS Error: #{error["errorMessage"]} (#{error["sourceName"]}:#{error["lineNumber"]})"
    end

    return unless example.exception && ENV["CAPTURE_SCREENSHOTS"]

    errors_path = Rails.root.join("log/seleniumfailures")
    FileUtils.mkdir_p(errors_path)

    summary_name = meta[:location].sub(/\A[.\/]+/, "").gsub(/\//, ":")
    screenshot_name = summary_name + ".png"
    driver.save_screenshot(errors_path.join(screenshot_name))

    # make a nice little html file for jenkins
    File.open(errors_path.join(summary_name + ".html"), "w") do |file|
      output_buffer = nil # Erubis wants this local var
      file.write SeleniumDriverSetup.error_template.result(binding)
    end

    puts meta[:location]
    puts "  Screenshot: #{errors_path.join(screenshot_name)}"
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
    attempts ||= 0
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
  rescue ServerStartupError
    attempts += 1
    retry if attempts <= 3
    $stderr.puts "unable to start server, giving up :'("
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
