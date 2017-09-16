# Copyright (C) 2017 - present Instructure, Inc.
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
module Canvas
  class DynamicSettings
    # A class for reading values from Consul
    #
    # @attr prefix [String] The prefix to be prepended to keys for querying.
    class PrefixProxy
      CONSUL_READ_OPTIONS = %i{stale}.freeze
      private_constant :CONSUL_READ_OPTIONS

      DEFAULT_TTL = 5.minutes
      # The TTL for cached values if none is specified in the constructor

      attr_reader :prefix, :tree, :service, :environment, :cluster

      # Build a new prefix proxy
      #
      # @param prefix [String] The prefix to be prepended to keys for querying.
      # @param tree [String] Which tree to use (config, private, store)
      # @param service [String] The service name to use (i.e. who owns the configuration). Defaults to canvas
      # @param environment [String] An optional environment to look for so that multiple Canvas environments can share Consul
      # @param cluster [String] An optional cluster to override region or global settings
      # @param default_ttl [ActiveSupport::Duration] The TTL to use for cached
      #   values when not specified to the fetch methods.
      # @param kv_client [Imperium::KV] The client to use for connecting to
      #   Consul, defaults to Imperium::KV.default_client
      def initialize(prefix = nil,
                     tree: :config,
                     service: :canvas,
                     environment: nil,
                     cluster: nil,
                     default_ttl: DEFAULT_TTL,
                     kv_client: Imperium::KV.default_client)
        @prefix = prefix
        @tree = tree
        @service = service
        @environment = environment
        @cluster = cluster
        @default_ttl = default_ttl
        @kv_client = kv_client
      end

      # Fetch the value at the requested key using the prefix passed to the
      # initializer.
      #
      # This method is intended to retreive a single key from the keyspace and
      # will not work for getting multiple values in a hash from the store. If
      # you need to access values nested deeper in the keyspace use #for_prefix
      # to move deeper in the nesting.
      #
      # @param key [String, Symbol] The key to fetch
      # @param ttl [ActiveSupport::Duration] The TTL for the value in the cache,
      #   defaults to value supplied to the constructor.
      # @return [String]
      # @return [nil] When no value was found
      def fetch(key, ttl: @default_ttl)
        fetch_object(key, ttl: ttl)&.values
      end
      alias [] fetch

      # Fetch the full object at the specified key including all metadata
      #
      # This method is intended to retreive a single key from the keyspace and
      # will not work for getting multiple values in a hash from the store. If
      # you need to access values nested deeper in the keyspace use #for_prefix
      # to move deeper in the nesting.
      #
      # @param key [String, Symbol] The key to fetch
      # @param ttl [ActiveSupport::Duration] The TTL for the value in the cache,
      #   defaults to value supplied to the constructor.
      # @return [Imperium::KVGETResponse]
      def fetch_object(key, ttl: @default_ttl)
        keys = [
          [tree, service, environment, cluster, prefix, key].compact.join("/"),
          [tree, service, environment, prefix, key].compact.join("/"),
          [tree, service, prefix, key].compact.join("/"), # for backcompat only
          ["global", tree, service, environment, prefix, key].compact.join("/"),
          ].uniq

        # cache with the most specific value
        Cache.fetch(keys.first, ttl: ttl) do
          result = nil
          keys.each do |full_key|
            result = @kv_client.get(full_key, *CONSUL_READ_OPTIONS)
            result = nil unless result&.status == 200
            break if result
          end
          result
        end
      rescue Imperium::TimeoutError => exception
        Cache.fallback_fetch(keys.first).tap do |val|
          if val
            Canvas::Errors.capture_exception(:consul, exception)
            val
          else
            raise
          end
        end
      end

      # Extend the prefix from this instance returning a new one.
      #
      # @param prefix_extension [String]
      # @param default_ttl [ActiveSupport::Duration] The default TTL to use when
      #  fetching keys from the extended keyspace, defaults to the same value as
      #  the receiver
      # @return [ProxyPrefix]
      def for_prefix(prefix_extension, default_ttl: @default_ttl)
        self.class.new(
          "#{@prefix}/#{prefix_extension}",
          tree: tree,
          service: service,
          environment: environment,
          cluster: cluster,
          default_ttl: default_ttl,
          kv_client: @kv_client
        )
      end
    end
  end
end
