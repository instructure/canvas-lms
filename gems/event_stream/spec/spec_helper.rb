begin
  require '../../spec/coverage_tool.rb'
  CoverageTool.start('event_stream-gem')
rescue LoadError => e
  puts "Error: #{e}"
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
