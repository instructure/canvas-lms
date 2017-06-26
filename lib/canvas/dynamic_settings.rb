#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_dependency 'canvas/dynamic_settings/cache'
require_dependency 'canvas/dynamic_settings/fallback_proxy'
require_dependency 'canvas/dynamic_settings/prefix_proxy'
require 'imperium'

module Canvas
  class DynamicSettings

    class Error < StandardError; end
    class ConsulError < Error; end
    class NoFallbackError < Error; end

    CONSUL_READ_OPTIONS = %i{recurse stale}.freeze
    KV_NAMESPACE = "config/canvas".freeze

    class << self
      attr_accessor :config, :environment
      attr_reader :base_prefix_proxy, :fallback_data

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

          init_values(conf_hash.fetch("init_values", {}))
          init_values(conf_hash.fetch("init_values_without_env", {}), use_env: false)

          @base_prefix_proxy = DynamicSettings::PrefixProxy.new(
            [KV_NAMESPACE, @environment.presence].compact.join('/'),
            kv_client: Imperium::KV.default_client
          )
        else
          @environment = @base_prefix_proxy = nil
        end
      end

      # Set the fallback data to use in leiu of Consul
      #
      # This isn't really meant for use in production, but as a convenience for
      # development where most won't want to run a consul agent/server.
      def fallback_data=(value)
        @fallback_data = value&.with_indifferent_access
      end

      # This is deprecated, use for_prefix to get a client that will fetch your
      # values for you and squawks like a hash so you don't have to change much.
      def find(key, use_env: true)
        if config.nil?
          return fallback_data.fetch(key) if fallback_data.present?
          raise(ConsulError, "Unable to contact consul without config")
        else
          store_get(key, use_env: use_env)
        end
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
      # @param default_ttl [ActiveSupport::Duration] How long to retain cached
      #   values
      def for_prefix(prefix, default_ttl: DynamicSettings::PrefixProxy::DEFAULT_TTL)
        if @base_prefix_proxy
          @base_prefix_proxy.for_prefix(prefix, default_ttl: default_ttl)
        elsif @fallback_data.present?
          DynamicSettings::FallbackProxy.new(@fallback_data[prefix])
        else
          raise NoFallbackError, 'DynamicSettings.fallback_data is not set and'\
            ' consul is not configured, unable to supply configuration values.'
        end
      end

      # This is deprecated, use for_prefix to get a client that will fetch your
      # values for you and squawks like a hash so you don't have to change much.
      #
      # settings found this way with nil expiry will be cached in the process
      # the first time they're asked for, and then can only be cleared with a SIGHUP
      # or restart of the process.  Make sure that's the behavior you want before
      # you use this method, or specify a timeout
      def from_cache(key, expires_in: nil, use_env: true)
        Canvas::DynamicSettings::Cache.fetch(key, ttl: expires_in) do
          self.find(key, use_env: use_env)
        end
      end

      def kv_client
        Imperium::KV.default_client
      end

      def reset_cache!(hard: false)
        Canvas::DynamicSettings::Cache.reset!
        @strategic_reserve = {} if hard
      end

      private

      def init_values(hash, use_env: true)
        hash.each do |parent_key, settings|
          settings.each do |child_key, value|
            store_put("#{parent_key}/#{child_key}", value, use_env: use_env)
          end
        end
      rescue Imperium::TimeoutError
        return false
      end

      def store_get(key, use_env: true)
        # store all values that we get here to
        # kind-of recover in case of big failure
        @strategic_reserve ||= {}
        parent_key = add_prefix_to(key, use_env)
        consul_response = kv_client.get(parent_key, *CONSUL_READ_OPTIONS)
        consul_value = consul_response.values

        @strategic_reserve[key] = consul_value
        consul_value
      rescue Imperium::TimeoutError => exception
        if @strategic_reserve.key?(key)
          # we have an old value for this key, log the error but recover
          Canvas::Errors.capture_exception(:consul, exception)
          return @strategic_reserve[key]
        else
          # didn't have an old value cached, raise the error
          raise
        end
      end

      def store_put(key, value, use_env: true)
        full_key = add_prefix_to(key, use_env)
        kv_client.put(full_key, value)
      end

      def add_prefix_to(key, use_env)
        if use_env && environment
          "#{KV_NAMESPACE}/#{environment}/#{key}"
        else
          "#{KV_NAMESPACE}/#{key}"
        end
      end
    end
  end
end
