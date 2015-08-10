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

  # Static IP addresses entered into Mobile Verify. Comment/Uncomment to set the url.
  # Mobile Apps will not connect to local test instances other than these.
  def host_url
    # @host_url = '10.0.15.241' # Ben's server
    @host_url = '10.0.15.242' # Taylor's server
    # @host_url = '10.0.15.244' # Tyler's server
    @host_url
  end

  # This assumes Appium server will be running on the same host as the Canvas-lms.
  def appium_server_url
    @appium_server_url = URI("http://#{host_url}:4723/wd/hub")
    @appium_server_url
  end

  def android_course_name
    @android_course_name = 'QA | Android'
    @android_course_name
  end

  def ios_course_name
    @ios_course_name = 'QA | iOS'
    @ios_course_name
  end

  # Appium settings are device specific. To list connected devices for Android run:
  #   $ <android_sdk_path>/platform-tools/adb devices
  def android_device_name
    @device_name = '05f034a7' # QA Nexus 7
    @device_name
  end

  # Appium settings are device specific. To get iOS device info:
  #   Settings > General > Version
  #   $ idevice_id -l ### lists connected devices by UDID
  #   $ idevice_id [UDID] ### prints device name
  #   $ idevice_id -l ### lists connected devices by UDID
  def ios_device
    device = 'iPad' # <--- TODO: change this line to setup environment for ios device
    case device
    when 'QA iPhone 6'
      @ios_version = '8.3'
      @device_name = 'QA iPhone 6'
      @ios_udid = 'd227f9716519ddf8959f941074d712fc5d215672'
      @ios_type = 'iPhone'
    when 'iPad'
      @ios_version = '8.4'
      @device_name = 'iPad'
      @ios_udid = 'b94ee387573a4a0a87c877becf36eb7224e0a80b'
      @ios_type = 'iPad'
    when 'Mobile User Testing 39'
      @ios_version = '8.4'
      @device_name = 'Mobile User Testing 39'
      @ios_udid = 'e192d707cd42f99c957bddc51e4fbe8aba43d9db'
      @ios_type = 'iPad'
    else
      raise('Unsupported ios device.')
    end

    # Appium is not yet integrated with Jenkins, so the only way to specify the app path for iOS
    # is to compile it locally with XCode, and update this method with the absolute path to the icanvas.app
    # file in your DerivedData folder. Make sure you choose the right subfolder (iphoneos for real devices).
    @ios_app_path = '/Users/twilson/Library/Developer/Xcode/DerivedData/iCanvas-fkfdbqxlcxqugldosdstapazsjaz/Build/Products/Debug-iphoneos/iCanvas.app'
    { versionNumber: @ios_version, deviceName: @device_name, udid: @ios_udid, app: @ios_app_path }
  end

  def implicit_wait_time
    @implicit_wait_time = 3
    @implicit_wait_time
  end
end
