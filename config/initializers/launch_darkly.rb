opts = {}
opts[:capacity] = 15000
opts[:flush_interval] = 60
opts[:diagnostic_opt_out] = true
config = LaunchDarkly::Config.new(opts)

Rails.configuration.launch_darkly_client = LaunchDarkly::LDClient.new(ENV['LAUNCH_DARKLY_SDK_KEY'], config)
