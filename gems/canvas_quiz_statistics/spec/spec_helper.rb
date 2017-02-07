begin
  require '../../spec/coverage_tool.rb'
  CoverageTool.start('canvas-quiz-statistics-gem')
rescue LoadError => e
  puts "Error: #{e} "
end

require 'byebug'
require 'canvas_quiz_statistics'

Constants = CanvasQuizStatistics::Analyzers::Base::Constants

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.color = true
  config.order = 'random'
end

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
