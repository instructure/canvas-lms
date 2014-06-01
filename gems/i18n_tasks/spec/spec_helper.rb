require 'simplecov'
require 'simplecov-rcov'

SimpleCov.use_merging
SimpleCov.merge_timeout(10000)
SimpleCov.command_name('i18n-tasks-gem')
SimpleCov.start('test_frameworks') do
  SimpleCov.coverage_dir('../../coverage')
  SimpleCov.at_exit {
    SimpleCov.result
  }
end

require 'i18n_tasks'

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.order = 'random'
end
