require 'mocha/api'

module MochaRspecAdapter
  include Mocha::API
  include ::RSpec::Mocks::ExampleMethods

  # rspec-mocks shadows mocha's implementations of kind_of, instance_of, and
  # anything. if you need those, please use rspec-mocks syntax

  def setup_mocks_for_rspec
    mocha_setup
    ::RSpec::Mocks.setup
  end

  def verify_mocks_for_rspec
    mocha_verify
    ::RSpec::Mocks.verify
  end

  def teardown_mocks_for_rspec
    mocha_teardown
    ::RSpec::Mocks.teardown
  end
end

RSpec.configure do |config|
  config.mock_with MochaRspecAdapter
end
