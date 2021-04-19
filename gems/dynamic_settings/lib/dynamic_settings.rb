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

require 'logger'
require 'active_support'
require 'active_support/core_ext'
require 'config_file'
require 'imperium'
require 'dynamic_settings/memory_cache'
require 'dynamic_settings/fallback_proxy'
require 'dynamic_settings/prefix_proxy'

module DynamicSettings

  class Error < StandardError; end
  class ConsulError < Error; end

  CONSUL_READ_OPTIONS = %i{recurse stale}.freeze
  KV_NAMESPACE = "config/canvas"
  CACHE_KEY_PREFIX = "dynamic_settings/"

  class << self
    attr_accessor :environment
    attr_reader :fallback_data, :kv_client, :config
    attr_writer :fallback_recovery_lambda, :cache, :logger

    def config=(conf_hash)
      @config = conf_hash
      if conf_hash.present?
        Imperium.configure do |config|
          config.ssl = conf_hash.fetch('ssl', true)
          config.host = conf_hash.fetch('host')
          config.port = conf_hash.fetch('port')
          config.token = conf_hash.fetch('acl_token', nil)

          config.connect_timeout = conf_hash['connect_timeout'] if conf_hash['connect_timeout']
          config.send_timeout = conf_hash['send_timeout'] if conf_hash['send_timeout']
          config.receive_timeout = conf_hash['receive_timeout'] if conf_hash['receive_timeout']
        end

        @environment = conf_hash['environment']
        @kv_client = Imperium::KV.default_client
        @data_center = conf_hash.fetch('global_dc', nil)
        @default_service = conf_hash.fetch('service', :canvas)
        @cache = conf_hash.fetch('cache', ::DynamicSettings::MemoryCache.new)
        @fallback_recovery_lambda = conf_hash.fetch('fallback_recovery_lambda', nil)
        @logger = conf_hash.fetch('logger', nil)
      else
        @environment = nil
        @kv_client = nil
        @default_service = :canvas
        @cache = ::DynamicSettings::MemoryCache.new
      end
    end

    def logger
      @logger ||= Rails.logger
    end

    def cache
      @cache ||= ::DynamicSettings::MemoryCache.new
    end

    def on_fallback_recovery(exception)
      if @fallback_recovery_lambda.present?
        @fallback_recovery_lambda.call(exception)
      end
    end

    def on_reload!
      @root_fallback_proxy = nil
      reset_cache!
    end

    # if we don't clear out the kv_client we can end up
    # with a shared file descriptor between processes
    def on_fork!
      @kv_client = Imperium::KV.default_client unless @kv_client.nil?
    end

    # Set the fallback data to use in leiu of Consul
    #
    # This isn't really meant for use in production, but as a convenience for
    # development where most won't want to run a consul agent/server.
    def fallback_data=(value)
      @fallback_data = value
      @root_fallback_proxy = if @fallback_data
        FallbackProxy.new(@fallback_data.with_indifferent_access)
      end
    end

    def root_fallback_proxy
      @root_fallback_proxy ||= FallbackProxy.new(ConfigFile.load("dynamic_settings").dup)
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
             data_center: nil)
      service ||= @default_service || :canvas
      if kv_client
        PrefixProxy.new(
          prefix,
          tree: tree,
          service: service,
          environment: @environment,
          cluster: cluster,
          default_ttl: default_ttl,
          kv_client: kv_client,
          data_center: data_center || @data_center,
          query_logging: @config.fetch('query_logging', true)
        )
      else
        proxy = root_fallback_proxy
        proxy = proxy.for_prefix(tree)
        proxy = proxy.for_prefix(service)
        proxy = proxy.for_prefix(prefix) if prefix
        proxy
      end
    end
    alias kv_proxy find

    def reset_cache!
      cache.delete_matched(/^#{CACHE_KEY_PREFIX}/)
    end
  end
end
