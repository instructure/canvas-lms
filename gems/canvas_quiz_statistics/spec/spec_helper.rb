require 'simplecov'
require 'simplecov-rcov'

SimpleCov.use_merging
SimpleCov.merge_timeout(10000)
SimpleCov.command_name('canvas-quiz-statistics-gem')
SimpleCov.start('test_frameworks') do
  SimpleCov.coverage_dir(File.join(File.dirname(__FILE__), '..', 'coverage'))
end

require 'canvas_quiz_statistics'

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.color = true
  config.order = 'random'

  support_files = File.join(
    File.dirname(__FILE__),
    'canvas_quiz_statistics',
    'support',
    '**',
    '*.rb'
  )

  Dir.glob(support_files).each { |file| require file }
end
