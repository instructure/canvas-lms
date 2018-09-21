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

    CONSUL_READ_OPTIONS = %i{recurse stale}.freeze
    KV_NAMESPACE = "config/canvas".freeze

    class << self
      attr_accessor :config, :environment
      attr_reader :fallback_data

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
        else
          @environment = nil
          @kv_client = nil
          @default_service = :canvas
        end
      end

      # Set the fallback data to use in leiu of Consul
      #
      # This isn't really meant for use in production, but as a convenience for
      # development where most won't want to run a consul agent/server.
      def fallback_data=(value)
        @fallback_data = value
        if @fallback_data
          @root_fallback_proxy = DynamicSettings::FallbackProxy.new(@fallback_data.with_indifferent_access)
        else
          @root_fallback_proxy = nil
        end
      end

      def root_fallback_proxy
        @root_fallback_proxy ||= DynamicSettings::FallbackProxy.new(ConfigFile.load("dynamic_settings"))
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
      def find( prefix = nil,
                tree: :config,
                service: nil,
                cluster: nil,
                default_ttl: DynamicSettings::PrefixProxy::DEFAULT_TTL,
                data_center: nil
              )
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
            data_center: @data_center
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

      def kv_client
        @kv_client
      end

      def reset_cache!
        Canvas::DynamicSettings::Cache.reset!
      end
    end
  end
end
