module SeleniumDriverSetup
  def setup_selenium

    browser = $selenium_config[:browser].try(:to_sym) || :firefox
    host_and_port

    path = $selenium_config[:paths].try(:[], browser)
    if path
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
    driver = nil
    begin
      tries ||= 3
      puts "Thread: provisioning selenium ruby firefox driver"
      driver = Selenium::WebDriver.for(:firefox, options)
    rescue StandardError => e
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

  def selenium_driver;
    $selenium_driver
  end

  alias_method :driver, :selenium_driver

  def firefox_profile
    profile = Selenium::WebDriver::Firefox::Profile.new
    profile.load_no_focus_lib=(true)
    profile.native_events = true

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

  def self.rack_app
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