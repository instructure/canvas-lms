require 'simplecov'
require 'simplecov-rcov'

SimpleCov.use_merging
SimpleCov.merge_timeout(10000)
SimpleCov.command_name('event_stream-gem')
SimpleCov.start('test_frameworks') do
  SimpleCov.coverage_dir('../../coverage')
  SimpleCov.at_exit {
    SimpleCov.result
  }
end

require 'event_stream'
require 'support/active_record'

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.order = 'random'
end

Time.zone = "UTC"
