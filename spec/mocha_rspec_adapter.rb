require 'mocha/api'

module MochaRspecAdapter
  include Mocha::API
  def setup_mocks_for_rspec
    mocha_setup
  end

  def verify_mocks_for_rspec
    mocha_verify
  end

  def teardown_mocks_for_rspec
    mocha_teardown
  end
end

RSpec.configure do |config|
  config.mock_with MochaRspecAdapter
end
