module Canvas
  class RedisConfig
    attr_reader :redis

    def initialize(servers, database=nil)
      @redis = RedisConfig.from_servers(servers)
      @redis.select database if database.present?
    end

    def self.from_settings(settings)
      RedisConfig.new(
        settings[:servers],
        settings[:database]
      )
    end

    def self.factory
      Bundler.require 'redis'
      ::Redis::Factory
    end

    def self.from_servers(servers)
      factory.create(servers.map { |s|
        # convert string addresses to options hash, and disable redis-cache's
        # built-in marshalling code
        factory.convert_to_redis_client_options(s).merge(:marshalling => false)
      })
    end

  end
end