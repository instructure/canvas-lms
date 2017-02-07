# Ensure we aren't doing silly things with expectations, such as:
#
# 1. `expect` in a `before` ... `before` implies it's before the spec, so
#    why are you testing things there?
# 2. `expect` without a `to` / `not_to` ... it will never get checked
# 3. specs with no expectations... what's the point?

module GreatExpectations
  class Error < StandardError
    def self.for(message, location = nil)
      error = new(message)
      bt = caller
      # not a legit backtrace, but this way the rspec error/context
      # will point right at the example in the file
      bt.unshift "#{File.expand_path(location)}:in block in <top (required)>'" if location
      error.set_backtrace(bt)
      error
    end
  end

  # default behavior, can be overridden with `.with_config`
  CONFIG = {
    # what to do if there's an `expect` in a `before`
    EARLY: :raise,

    # what to do if an `expect` has no `to`
    UNCHECKED: :raise,

    # what to do if a spec has no `expect`s
    MISSING: :warn
  }.freeze

  module Example
    # allow expectations at the last possible second (right after the
    # inner-most before hooks run)
    def run_before_example
      super
      GreatExpectations.example_started(self)
    end

    # immediately before running any after hooks, ensure the spec had some
    # expectations. this includes mocha/rspec-mocks which will be verified
    # in the super call
    def run_after_example
      GreatExpectations.example_finished
      super
    end
  end

  module AssertionDelegator
    def assert(*)
      GreatExpectations.expectation_checked
      super
    end
  end

  module ExpectationTarget
    def initialize(*)
      GreatExpectations.expectation_created(self)
      super
    end

    def to(*)
      GreatExpectations.expectation_checked(self)
      super
    end

    def not_to(*)
      GreatExpectations.expectation_checked(self)
      super
    end
    alias to_not not_to
  end

  class << self
    attr_accessor :config
    attr_accessor :current_example
    attr_accessor :expectation_count

    def install!
      self.config = CONFIG
      ::RSpec::Core::Example.prepend Example
      ::RSpec::Expectations::ExpectationTarget.prepend ExpectationTarget
      ::RSpec::Rails::MinitestAssertionAdapter::AssertionDelegator.prepend AssertionDelegator
    end

    def with_config(config)
      orig_config = @config
      @config = orig_config.merge(config)
      yield
    ensure
      @config = orig_config
    end

    def expectation_created(expectation)
      assert_not_early!
      unchecked_expectations << expectation
    end

    def expectation_checked(expectation = nil)
      unchecked_expectations.delete(expectation) if expectation
      self.expectation_count += 1
    end

    def unchecked_expectations
      @unchecked_expectations ||= Set.new
    end

    def example_started(example)
      self.current_example = example
      self.expectation_count = 0
    end

    def example_finished
      return if current_example.nil? || # like if we `skip` in a before
                current_example.exception ||
                current_example.skipped? ||
                current_example.pending?

      assert_not_unchecked!
      assert_not_missing!
    rescue Error
      current_example.set_exception($ERROR_INFO)
    ensure
      self.current_example = nil
      unchecked_expectations.clear
    end

    def assert_not_early!
      return if current_example
      generate_error config[:EARLY], "Don't `expect` outside of the spec itself. `before`/`after` should only be used for setup/teardown"
    end

    def assert_not_unchecked!
      return if unchecked_expectations.empty?
      generate_error config[:UNCHECKED], "This spec has unchecked expectations, i.e. you forgot to call `to` or `not_to`", current_example.location
    end

    def assert_not_missing!
      # vanilla expectation
      return if expectation_count > 0

      # rspec message expectations
      return if ::RSpec::Mocks.space.proxies.any? do |_, proxy|
        proxy.instance_variable_get(:@method_doubles).any? do |_, double|
          double.expectations.any?
        end
      end
      return if ::RSpec::Mocks.space.any_instance_recorders.any? do |_, recorder|
        recorder.instance_variable_get(:@expectation_set)
      end

      # mocha expectations
      return if ::Mocha::Mockery.instance.send(:expectations).any? do |expectation|
        expectation.instance_variable_get(:@cardinality).needs_verifying?
      end

      generate_error config[:MISSING], "This spec has no expectations. Add one!", current_example.location
    end

    def generate_error(action, message, location = nil)
      if action == :raise
        raise Error.for(message, location)
      else
        $stderr.puts "\e[31mWarning: #{message}"
        $stderr.puts "See: " + (location || CallStackUtils.best_line_for(caller)) + "\e[0m"
      end
    end
  end
end
