require 'folio/rails'
require 'folio/will_paginate/active_record' if defined?(CANVAS_RAILS3) && CANVAS_RAILS3

require 'paginated_collection'

require 'support/active_record'

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.color_enabled = true
  config.order = 'random'
end