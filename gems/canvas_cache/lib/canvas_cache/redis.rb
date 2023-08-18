# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require "config_file"
require "active_support/core_ext/module/introspection"
require "active_support/core_ext/object/blank"
require "guard_rail"
require "redis"

# see https://github.com/redis/redis-rb/pull/739

module CanvasCache
  module Redis
    module Scripting
      module Module
      end
    end

    class UnsupportedRedisMethod < RuntimeError
    end

    module Client
      def disconnect_if_idle(since_when)
        disconnect if !@process_start || @process_start < since_when
      end
    end

    module Distributed
      def initialize(addresses, options = {})
        options[:ring] ||= HashRing.new([], options[:replicas], options[:digest])
        super
      end
    end

    class << self
      def redis
        raise "Redis is not enabled for this install" unless enabled?

        return Rails.cache.redis if config == "cache_store"

        @redis ||= ActiveSupport::Cache::RedisCacheStore.build_redis(**config.deep_symbolize_keys)
      end

      def config
        @config ||= ConfigFile.load("redis")
      end

      def enabled?
        @enabled ||= config.present?
      end

      def disconnect!
        return unless @redis
        # We're sharing redis connections between CanvasCache::Redis.redis and Rails.cache,
        # so don't call disconnect on the cache too.
        return if Rails.cache.respond_to?(:redis) && @redis == Rails.cache.redis

        @redis = nil
      end

      def reset_config!
        @config = nil
        @enabled = nil
      end

      # try to grab a lock in Redis, returning false if the lock can't be held. If
      # the lock is grabbed and `ttl` is given, it'll be set to expire after `ttl`
      # seconds.
      def lock(key, ttl = nil)
        return true unless enabled?

        ttl = (ttl.to_f * 1000).to_i if ttl
        full_key = lock_key(key)
        redis.set(full_key, 1, px: ttl, nx: true)
      end

      # unlock a previously grabbed Redis lock. This doesn't do anything to verify
      # that this process took the lock.
      def unlock(key)
        redis.del(lock_key(key))
        true
      end

      def lock_key(key)
        "lock:#{key}"
      end

      def log_style
        # supported: 'off', 'compact', 'json'
        @log_style ||= ConfigFile.load("redis")&.[]("log_style") || "compact"
      end

      def patch
        return if ::Redis < self # rubocop:disable Style/YodaCondition

        Bundler.require "redis"
        require "redis/distributed"

        RedisClient.register(RedisClient::Logging)
        RedisClient.register(RedisClient::Twemproxy)
        RedisClient.register(RedisClient::MaxClients)

        ::Redis.instance_methods.each do |m|
          next unless ::Redis.instance_method(m).owner.module_parent == ::Redis::Commands

          def_failsafe_method(self, m)
        end
        def_failsafe_method(self, :pipelined)
        def_failsafe_method(self, :multi)
        def_failsafe_method(Scripting::Module, :run)

        ::Redis::Scripting::Module.prepend(Scripting::Module) if defined?(::Redis::Scripting::Module)
        ::Redis.prepend(Redis)
        ::Redis::Client.prepend(Client)
        ::Redis::Distributed.prepend(Distributed)
      end

      private

      def def_failsafe_method(klass, method)
        klass.class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{method}(*, **kwargs)               # def get(*, **kwargs)
            has_failsafe = kwargs.key?(:failsafe)  #   has_failsafe = kwargs.key?(:failsafe)
            failsafe = kwargs.delete(:failsafe)    #   failsafe = kwargs.delete(:failsafe)
                                                   #
            super                                  #   super
          rescue ::Redis::BaseConnectionError      # rescue ::Redis::BaseConnectionError
            return failsafe if has_failsafe        #   return failsafe if has_failsafe
                                                   #
            raise                                  #   raise
          end                                      # end
        RUBY
      end
    end
  end
end
