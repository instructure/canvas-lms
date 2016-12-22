require 'live_events'
require 'thread'

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.color = true
  config.order = 'random'
end

Thread.abort_on_exception = true
