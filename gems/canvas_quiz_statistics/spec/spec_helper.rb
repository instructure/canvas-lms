begin
  require '../../spec/coverage_tool.rb'
  CoverageTool.start('canvas-quiz-statistics-gem')
rescue LoadError => e
  puts "Error: #{e} "
end

require 'canvas_quiz_statistics'

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.color = true
  config.order = 'random'

  File.join(File.dirname(__FILE__), 'canvas_quiz_statistics').tap do |cwd|
    # spec support in support/
    Dir.glob(File.join([
                           cwd, 'support', '**', '*.rb'
                       ])).each { |file| require file }

    # specs for shared metrics in analyzers/shared_metrics
    Dir.glob(File.join([
                           cwd, 'analyzers', 'shared_metrics', '**', '*.rb'
                       ])).each { |file| require file }
  end
end
