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
  # - instance_of

  def anything
    ::Mocha::ParameterMatchers::Anything.new
  end

  def rspec_anything
    ::RSpec::Mocks::ArgumentMatchers::AnyArgMatcher::INSTANCE
  end

  def instance_of(klass)
    ::Mocha::ParameterMatchers::InstanceOf.new(klass)
  end

  def rspec_instance_of(klass)
    ::RSpec::Mocks::ArgumentMatchers::InstanceOf.new(klass)
  end
end

RSpec.configure do |config|
  config.mock_with MochaRspecAdapter
end
