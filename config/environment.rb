require File.expand_path("../canvas_rails3", __FILE__)

if CANVAS_RAILS2
  unless Gem.respond_to?(:source_index)
    module Gem
      def self.source_index
        sources
      end

      def self.cache
        sources
      end

      SourceIndex = Specification

      class SourceList
        # If you want vendor gems, this is where to start writing code.
        def search( *args ); []; end
        def each( &block ); end
        include Enumerable
      end
    end
  end

  def environment_configuration(config)
    yield(config)
  end

  # Bootstrap the Rails environment, frameworks, and default configuration
  require File.expand_path('../boot', __FILE__)

  Rails::Initializer.run do |config|
    eval(File.read(File.expand_path("../shared_boot.rb", __FILE__)), binding, "config/shared_boot.rb", 1)
  end
else
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
end
