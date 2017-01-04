require 'paginated_collection'
require 'will_paginate/array'

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.color = true
  config.order = 'random'
end
