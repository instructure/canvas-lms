require 'linked_in'
require 'mocha'

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.color_enabled true

  config.order = 'random'

  config.mock_framework = :mocha

end
