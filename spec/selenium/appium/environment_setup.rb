module EnvironmentSetup

  $appium_config = ConfigFile.load('appium')

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
end
