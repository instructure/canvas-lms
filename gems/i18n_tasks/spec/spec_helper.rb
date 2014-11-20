
begin
  require '../../spec/coverage.rb'
  CoverageTool.start('i18n-tasks-gem')
rescue LoadError => e
  puts "Error: #{e} "
end

require 'i18n_tasks'

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.order = 'random'
end
