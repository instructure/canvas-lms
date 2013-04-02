# compatibility shim for plugins that aren't converted to Shackles yet
ActiveRecord::Base::ConnectionSpecification.class_eval do
  class << self
    def environment
      Shackles.environment
    end

    def explicit_user
      Shackles.global_config[:username]
    end

    def with_environment(env)
      Shackles.activate(env) { yield }
    end

    def connection_handlers
      Shackles.connection_handlers
    end
  end
end

if ActiveRecord::Base::ConnectionSpecification.respond_to?(:ensure_handler)
  Shackles.module_eval do
    def self.ensure_handler
      ActiveRecord::Base::ConnectionSpecification.instance_variable_set(:@connection_handlers, connection_handlers)
      ActiveRecord::Base::ConnectionSpecification.ensure_handler
    end
  end
end
