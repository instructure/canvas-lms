require 'google_drive'
require 'byebug'

DRIVE_FIXTURES_PATH = File.dirname(__FILE__) + '/fixtures/google_drive/'

def load_fixture(filename)
  File.read(DRIVE_FIXTURES_PATH + filename)
end


RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.order = 'random'
end
