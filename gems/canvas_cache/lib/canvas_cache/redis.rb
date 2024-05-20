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
require "redis_client/cluster"

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
      def self.prepended(klass)
        super

        klass.attr_accessor :last_command_at
      end

      def disconnect_if_idle(since_when)
        close if last_command_at.nil? || last_command_at < since_when
      end
    end

    module Cluster
      def disconnect_if_idle(since_when)
        @router.instance_variable_get(:@node).clients.each { |c| c.disconnect_if_idle(since_when) }
      end
    end

    module IgnorePipelinedKey
      def pipelined(_key = nil, **kwargs, &)
        # ignore key; only useful for distributed
        super(**kwargs, &)
      end
    end

    module Distributed
      def initialize(addresses, options = {})
        options[:ring] ||= HashRing.new([], options[:replicas], options[:digest])
        super
      end

      def pipelined(key = nil, ...)
        return super(...) unless key

        node_for(key).pipelined(...)
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

        @redis.close
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

        # Redis::Distributed manually wraps every command, and not all of those
        # wrappers support kwargs, so we have to add the failsafe here
        ::Redis::Distributed.instance_methods.each do |m|
          next unless ::Redis::Commands.instance_methods.include?(m)
          next if ::Redis::Distributed.instance_method(m).parameters.any? { |type, _name| type == :keyrest }

          def_failsafe_method(Distributed, m)
        end

        ::Redis::Scripting::Module.prepend(Scripting::Module) if defined?(::Redis::Scripting::Module)
        ::Redis.prepend(Redis)
        ::Redis.prepend(IgnorePipelinedKey)
        ::RedisClient.prepend(Client)
        ::Redis::Cluster::Client.prepend(Cluster)
        ::RedisClient::Cluster.prepend(IgnorePipelinedKey)
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
