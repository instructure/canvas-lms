require 'mocha/api'

module MochaRspecAdapter
  include Mocha::API
  include ::RSpec::Mocks::ExampleMethods

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

  # mocha and rspec both define:
  # - anything

  def anything
    ::Mocha::ParameterMatchers::Anything.new
  end

  def rspec_anything
    ::RSpec::Mocks::ArgumentMatchers::AnyArgMatcher::INSTANCE
  end
end

RSpec.configure do |config|
  config.mock_with MochaRspecAdapter
end
