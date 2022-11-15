Rails.configuration.launch_darkly_client = LaunchDarkly::LDClient.new(sdk_key: ENV['LAUNCH_DARKLY_SDK_KEY'])
