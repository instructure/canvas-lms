require 'canvas_panda_pub'

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.color = true
  config.order = 'random'
end

require 'webmock/rspec'
