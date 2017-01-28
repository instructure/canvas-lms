begin
  require '../../spec/coverage_tool.rb'
  CoverageTool.start('i18n-tasks-gem')
rescue LoadError => e
  puts "Error: #{e} "
end

require 'i18n_tasks'

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.order = 'random'
end
