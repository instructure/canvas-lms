# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require "logger"
require "active_support"
require "active_support/core_ext"
require "config_file"
require "diplomat"
require "dynamic_settings/circuit_breaker"
require "dynamic_settings/memory_cache"
require "dynamic_settings/null_request_cache"
require "dynamic_settings/fallback_proxy"
require "dynamic_settings/prefix_proxy"

module DynamicSettings
  CONSUL_READ_OPTIONS = %i[recurse stale].freeze
  KV_NAMESPACE = "config/canvas"
  CACHE_KEY_PREFIX = "dynamic_settings/"

  class << self
    attr_accessor :environment, :fallback_data
    attr_reader :use_consul, :config
    attr_writer :fallback_recovery_lambda, :retry_lambda, :cache, :request_cache, :logger

    def config=(conf_hash)
      @config = conf_hash
      if conf_hash.present?
        Diplomat.configure do |config|
          need_ssl = conf_hash.fetch("ssl", true)
          config.url = "#{need_ssl ? "https://" : "http://"}#{conf_hash.fetch("host")}:#{conf_hash.fetch("port")}"
          config.acl_token = conf_hash.fetch("acl_token", nil)

          options = { request: {} }
          options[:request][:open_timeout] = conf_hash["connect_timeout"] if conf_hash["connect_timeout"]
          options[:request][:timeout] = conf_hash["timeout"] if conf_hash["timeout"]
          config.options = options
        end

        @environment = conf_hash["environment"]
        @use_consul = true
        @data_center = conf_hash.fetch("global_dc", nil)
        @default_service = conf_hash.fetch("service", :canvas)
        @cache = conf_hash.fetch("cache", ::DynamicSettings::MemoryCache.new)
        @request_cache = conf_hash.fetch("request_cache", ::DynamicSettings::NullRequestCache.new)
        @fallback_recovery_lambda = conf_hash.fetch("fallback_recovery_lambda", nil)
        @retry_lambda = conf_hash.fetch("retry_lambda", nil)
        @logger = conf_hash.fetch("logger", nil)
      else
        @environment = nil
        @use_consul = false
        @default_service = :canvas
        @cache = nil
        @request_cache = nil
      end
    end

    def logger
      @logger ||= Rails.logger
    end

    def cache
      @cache ||= ::DynamicSettings::MemoryCache.new
    end

    def request_cache
      @request_cache ||= ::DynamicSettings::NullRequestCache.new
    end

    def on_fallback_recovery(exception)
      @fallback_recovery_lambda&.call(exception)
    end

    def on_retry(exception)
      @retry_lambda&.call(exception)
    end

    def on_reload!
      reset_cache!
    end

    # The fallback data to use in leiu of Consul
    #
    # This isn't really meant for use in production, but as a convenience for
    # development where most won't want to run a consul agent/server.
    def config_data
      # fallback_data is only relevant when set via accessor in specs
      return @fallback_data if @fallback_data

      @config_data ||= ConfigFile.load("dynamic_settings")
    end

    # Build an object used to interacting with consul for the given
    # keyspace prefix.
    #
    # If using fallback data for values it is queried by the returned object
    # instead of a Consul agent/server. The decision between using fallback
    # data or consul is driven by whether or not consul is configured.
    #
    # @param prefix [String] The portion to extend the base prefix with
    #   (base prefix: 'config/canvas/<environment>')
    # @param tree [String] Which tree to use (config, private, store)
    # @param service [String] The service name to use (i.e. who owns the configuration). Defaults to canvas
    # @param cluster [String] An optional cluster to override region or global settings
    # @param default_ttl [ActiveSupport::Duration] How long to retain cached
    #   values
    # @param data_center [String] location of the data_center the proxy is pointing to
    def find(prefix = nil,
             tree: :config,
             service: nil,
             cluster: nil,
             default_ttl: PrefixProxy::DEFAULT_TTL,
             data_center: nil,
             ignore_fallback_overrides: false)
      service ||= @default_service || :canvas
      if use_consul
        PrefixProxy.new(
          prefix,
          tree:,
          service:,
          environment: @environment,
          cluster:,
          default_ttl:,
          data_center: data_center || @data_center,
          query_logging: @config.fetch("query_logging", true),
          retry_limit: @config.fetch("retry_limit", 1),
          retry_base: @config.fetch("retry_base", 1.4),
          circuit_breaker: @config.fetch("circuit_breaker", nil)
        )
      else
        proxy = FallbackProxy.new(config_data.deep_dup, ignore_fallback_overrides:)
        proxy = proxy.for_prefix(tree)
        proxy = proxy.for_prefix(service)
        proxy = proxy.for_prefix(prefix) if prefix
        proxy
      end
    end
    alias_method :kv_proxy, :find

    def reset_cache!
      # Only Redis glob strings are supported! see: https://redis.io/commands/keys/
      cache.delete_matched("#{CACHE_KEY_PREFIX}*")
    end
  end
end
