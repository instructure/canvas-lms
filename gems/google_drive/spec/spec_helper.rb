require 'google_drive'
require 'byebug'
require 'timecop'
require 'webmock/rspec'

DRIVE_FIXTURES_PATH = File.dirname(__FILE__) + '/fixtures/google_drive/'

def load_fixture(filename)
  File.read(DRIVE_FIXTURES_PATH + filename)
end

WebMock.disable_net_connect!(allow_localhost: true)
RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.color = true

  config.order = 'random'
end


module Rails
  def self.cache
    @cache ||= ActiveSupport::Cache::MemoryStore.new
  end
end
