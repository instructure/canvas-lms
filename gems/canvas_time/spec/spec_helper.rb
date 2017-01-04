require 'canvas_time'
require 'timecop'

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.order = 'random'
  Time.zone = 'UTC'
end
