ActiveRecord::Base::ConnectionSpecification.class_eval do
  @@environment = ENV['RAILS_DATABASE_ENVIRONMENT'].presence.try(:to_sym)
  @@explicit_user = ENV['RAILS_DATABASE_USER'].presence

  cattr_accessor :environment, :explicit_user

  def self.environment
    @@environment
  end

  def config
    @current_config ||= @config
    @current_config_key ||= []
    return @current_config if @current_config_key == [@@environment, @@explicit_user]
    @current_config_key = [@@environment, @@explicit_user]
    @current_config = @config.dup
    if @@environment && @config.has_key?(@@environment)
      @current_config.merge!(@config[@@environment].symbolize_keys)
    end
    @current_config[:username] = @current_config[:username].gsub('{schema}', @current_config[:schema_search_path]) if @current_config[:username] && @current_config[:schema_search_path]
    if @@explicit_user
      @current_config[:username] = @@explicit_user
      @current_config.delete(:password)
    end
    @current_config
  end

  def self.with_environment(environment)
    return yield if environment == @@environment
    begin
      old_environment = @@environment
      @@environment = environment
      ActiveRecord::Base.connection_handler.clear_all_connections! unless Rails.env.test?
      yield
    ensure
      @@environment = old_environment
      ActiveRecord::Base.connection_handler.clear_all_connections! unless Rails.env.test?
    end
  end

  # for use from script/console ONLY
  def self.switch_user!(user)
    @@explicit_user = user
    ActiveRecord::Base.connection_handler.clear_all_connections!
  end
  def self.switch_environment!(environment)
    @@environment = environment
    ActiveRecord::Base.connection_handler.clear_all_connections!
  end
end
