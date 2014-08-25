module Canvas
  class RedisConfig
    attr_reader :redis

    def initialize(servers, database=nil, options=nil)
      @redis = RedisConfig.from_servers(servers, options)
      @redis.select database if database.present?
    end

    def self.from_settings(settings)
      RedisConfig.new(
        settings[:servers],
        settings[:database],
        settings.except(:servers, :database).symbolize_keys
      )
    end

    def self.factory
      Bundler.require 'redis'
      ::Redis::Factory
    end

    def self.from_servers(servers, options)
      factory.create(servers.map { |s|
        # convert string addresses to options hash, and disable redis-cache's
        # built-in marshalling code
        factory.convert_to_redis_client_options(s).merge(:marshalling => false).merge(options || {})
      })
    end

  end
end
