require 'socket'
require 'timeout'
require_relative '../../spec_helper'
require_relative '../test_setup/common_helper_methods/login_and_session_methods'
require_relative '../test_setup/common_helper_methods/other_helper_methods'

module EnvironmentSetup
  # All test environments must be seeded with this Developer Key. The only attribute allowed
  # to change is the *redirect_uri* which contains the static IP address of the Canvas-lms
  # environment, but do not change it; modify the *host_url* method instead.
  def create_developer_key
    if @appium_dev_key.nil?
      truncate_table(DeveloperKey) if @appium_dev_key.nil?
      @appium_dev_key = DeveloperKey.create!(
        name: 'appium_developer_key',
        tool_id: '68413514',
        email: 'admin@instructure.com',
        redirect_uri: "http://#{host_url}",
        api_key: 'w33UkRtGDXIjQPm32of6qDi6CIAqfeQw4lFDu8CP8IXOkerc8Uw7c3ZNvp1tqBcE'
      )
    end
    @appium_dev_key
  end

  # TODO: update when Appium is integrated with Jenkins, append $server_port
  def school_domain
    $appium_config[:school_domain]
  end

  # Static IP addresses entered into Mobile Verify. Comment/Uncomment to set the url.
  # Mobile Apps will not connect to local test instances other than these.
  def host_url
    $appium_config[:appium_host_url]
  end

  # This assumes Appium server will be running on the same host as the Canvas-lms.
  def appium_server_url
    URI("http://#{host_url}:4723/wd/hub")
  end

  def android_course_name
    'QA | Android'
  end

  def ios_course_name
    'QA | iOS'
  end

  # Appium settings are device specific. To list connected devices for Android run:
  #   $ <android_sdk_path>/platform-tools/adb devices
  def android_device_name
    $appium_config[:android_udid]
  end

  # Appium settings are device specific. To get iOS device info:
  #   Settings > General > Version
  #   $ idevice_id -l ### lists connected devices by UDID
  #   $ idevice_id [UDID] ### prints device name
  #   $ idevice_id -l ### lists connected devices by UDID
  def ios_device
    { versionNumber: $appium_config[:ios_version],
      deviceName: $appium_config[:ios_device_name],
      udid: $appium_config[:ios_udid],
      app: $appium_config[:ios_app_path] }
  end

  def ios_app_path
    $appium_config[:ios_app_path]
  end

  def implicit_wait_time
    3
  end

  # ====================================================================================================================
  # Extracted from spec/selenium/test_setup/selenium_driver_setup.rb
  # Modified for Mobile App automation: all things Selenium removed
  # ====================================================================================================================

  include I18nUtilities

  $appium_config = ConfigFile.load("appium") || {}
  SERVER_IP = $appium_config[:server_ip] || UDPSocket.open do |s|
    s.connect('8.8.8.8', 1)
    s.addr.last
  end
  BIND_ADDRESS = $appium_config[:bind_address] || '0.0.0.0'
  SECONDS_UNTIL_COUNTDOWN = 5
  SECONDS_UNTIL_GIVING_UP = 20
  MAX_SERVER_START_TIME = 60
  THIS_ENV = ENV['TEST_ENV_NUMBER'].to_i
  THIS_ENV = 1 if ENV['TEST_ENV_NUMBER'].blank?
  WEBSERVER = (ENV['WEBSERVER'] || 'thin').freeze

  $server_port = nil
  $app_host_and_port = nil

  def host_and_port
    if $appium_config[:host] && $appium_config[:port] && !$appium_config[:host_and_port]
      $appium_config[:host_and_port] = "#{$appium_config[:host]}:#{$appium_config[:port]}"
    end
  end

  # Runs a port scan unless the appium.yml file defines :server_port
  def self.setup_host_and_port
    ENV['CANVAS_CDN_HOST'] = "canvas.instructure.com"
    if $appium_config[:server_port]
      $server_port = $appium_config[:server_port]
      $app_host_and_port = "#{SERVER_IP}:#{$server_port}"
      return $server_port
    end

    # find an available socket
    s = Socket.new(:INET, :STREAM)
    s.setsockopt(:SOCKET, :REUSEADDR, true)
    s.bind(Addrinfo.tcp(SERVER_IP, 0))

    $server_port = s.local_address.ip_port
    if $appium_config[:browser] == 'ie'
      # makes default URL for selenium the external IP of the box for standalone sel servers
      server_ip = `curl http://instance-data/latest/meta-data/public-ipv4` # command for aws boxes gets external ip
    else
      server_ip = s.local_address.ip_address
    end

    $app_host_and_port = "#{server_ip}:#{s.local_address.ip_port}"
    puts "Found available port: #{$app_host_and_port}"

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
      puts "No web server specified, defaulting to WEBrick"
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
    shutdown
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
    require_relative '../test_setup/servers/thin_server'
    SpecFriendlyThinServer.run(self.rack_app, BindAddress: BIND_ADDRESS, Port: $server_port, AccessLog: [])
    self.shutdown_webserver(SpecFriendlyThinServer)
  end

  def self.start_in_process_webrick_server
    require_relative '../test_setup/servers/webrick_server'
    SpecFriendlyWEBrickServer.run(self.rack_app, BindAddress: BIND_ADDRESS, Port: $server_port, AccessLog: [])
    self.shutdown_webserver(SpecFriendlyWEBrickServer)
  end

  # ====================================================================================================================
  # Extracted from spec/selenium/common.rb
  # Modified for Mobile App automation: all things Selenium removed
  # ====================================================================================================================

  shared_context 'in-process server appium tests' do
    include OtherHelperMethods
    include LoginAndSessionMethods

    # set up so you can use rails urls helpers in your selenium tests
    include Rails.application.routes.url_helpers

    prepend_before :all do
      $in_proc_webserver_shutdown ||= EnvironmentSetup.start_webserver(WEBSERVER)
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

    after(:each) do
      EnvironmentSetup.disallow_requests!
      truncate_all_tables unless self.use_transactional_fixtures
    end
  end
end
