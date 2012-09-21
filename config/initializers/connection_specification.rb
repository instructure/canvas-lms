ActiveRecord::Base::ConnectionSpecification.class_eval do

  cattr_accessor :environment, :explicit_user
  self.environment = ENV['RAILS_DATABASE_ENVIRONMENT'].presence.try(:to_sym)
  self.explicit_user = ENV['RAILS_DATABASE_USER'].presence

  def config
    @current_config ||= @config
    @current_config_key ||= []
    return @current_config if @current_config_key == [self.class.environment, self.class.explicit_user]
    @current_config_key = [self.class.environment, self.class.explicit_user]
    @current_config = @config.dup
    if self.class.environment && @config.has_key?(self.class.environment)
      @current_config.merge!(@config[self.class.environment].symbolize_keys)
    end

    @current_config.keys.each do |key|
      next unless @current_config[key].is_a?(String)
      @current_config[key] = I18n.interpolate_hash(@current_config[key], @current_config)
    end

    if self.class.explicit_user
      @current_config[:username] = self.class.explicit_user
      @current_config.delete(:password)
    end

    @current_config.instance_variable_set(:@spec, self)
    def @current_config.[]=(key, value)
      @spec.instance_variable_set(:@current_config_key, nil)
      @spec.instance_variable_get(:@config)[key] = value
    end

    @current_config
  end

  def config=(value)
    @config = value
    @current_config_key = nil
  end

  def self.with_environment(environment)
    return yield if environment == self.environment
    begin
      self.save_handler
      old_environment = self.environment
      self.environment = environment
      ActiveRecord::Base.connection_handler = self.ensure_handler unless Rails.env.test?
      yield
    ensure
      self.environment = old_environment
      ActiveRecord::Base.connection_handler = self.ensure_handler unless Rails.env.test?
    end
  end

  def self.save_handler
    @connection_handlers ||= {}
    @connection_handlers[self.environment] ||= ActiveRecord::Base.connection_handler
  end

  unless self.respond_to?(:ensure_handler)
    def self.ensure_handler
      new_handler = @connection_handlers[self.environment]
      if !new_handler
        new_handler = @connection_handlers[self.environment] = ActiveRecord::ConnectionAdapters::ConnectionHandler.new
        ActiveRecord::Base.connection_handler.connection_pools.each do |model, pool|
          new_handler.establish_connection(model, pool.spec)
        end
      end
      new_handler
    end
  end

  def self.connection_handlers
    self.save_handler
    @connection_handlers
  end

  # for use from script/console ONLY; these will still disconnect
  def self.switch_user!(user)
    self.explicit_user = user
    ActiveRecord::Base.connection_handler.clear_all_connections!
  end

  def self.switch_environment!(environment)
    self.save_handler
    self.environment = environment
    ActiveRecord::Base.connection_handler = self.ensure_handler
  end
end

ActiveRecord::ConnectionAdapters::ConnectionHandler.class_eval do
  %w{clear_active_connections clear_reloadable_connections
     clear_all_connections verify_active_connections }.each do |method|
    # double-require prevention
    next if self.instance_methods.include?("#{method}_without_multiple_environments!")
    class_eval(<<EOS)
      def #{method}_with_multiple_environments!
        ActiveRecord::Base::ConnectionSpecification.connection_handlers.values.each(&:#{method}_without_multiple_environments!)
      end
EOS
    alias_method_chain "#{method}!".to_sym, :multiple_environments
  end
end
