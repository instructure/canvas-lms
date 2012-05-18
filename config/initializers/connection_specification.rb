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
    @current_config[:username] = @current_config[:username].gsub('{schema}', @current_config[:schema_search_path]) if @current_config[:username] && @current_config[:schema_search_path]
    if self.class.explicit_user
      @current_config[:username] = self.class.explicit_user
      @current_config.delete(:password)
    end
    @current_config
  end

  def self.with_environment(environment)
    return yield if environment == self.environment
    begin
      old_environment = self.environment
      self.environment = environment
      ActiveRecord::Base.connection_handler.clear_all_connections! unless Rails.env.test?
      yield
    ensure
      self.environment = old_environment
      ActiveRecord::Base.connection_handler.clear_all_connections! unless Rails.env.test?
    end
  end

  # for use from script/console ONLY
  def self.switch_user!(user)
    self.explicit_user = user
    ActiveRecord::Base.connection_handler.clear_all_connections!
  end
  def self.switch_environment!(environment)
    self.environment = environment
    ActiveRecord::Base.connection_handler.clear_all_connections!
  end
end
