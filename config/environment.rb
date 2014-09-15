def environment_configuration(_config)
  CanvasRails::Application.configure do
    yield(config)
  end
end

# Load the rails application
require File.expand_path('../application', __FILE__)

ActiveSupport::Deprecation.module_eval do
  class << self
    def warn_with_single_instance_check(message = nil, callstack = caller)
      @warned ||= Set.new
      return if @warned.include?(callstack)
      @warned << callstack
      warn_without_single_instance_check(message, callstack)
    end
    alias_method_chain :warn, :single_instance_check
  end
end

# Initialize the rails application
CanvasRails::Application.initialize!
