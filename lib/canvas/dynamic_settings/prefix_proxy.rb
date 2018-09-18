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
                     kv_client: Imperium::KV.default_client,
                     data_center: nil)
        @prefix = prefix
        @tree = tree
        @service = service
        @environment = environment
        @cluster = cluster
        @default_ttl = default_ttl
        @kv_client = kv_client
        @data_center = data_center
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
        keys = [
          full_key(key),
          [tree, service, environment, prefix, key].compact.join("/"),
        ].uniq

        fallback_keys = [
          [tree, service, prefix, key].compact.join("/"),
          full_key(key, global: true),
          ["global", tree, service, prefix, key].compact.join("/"),
        ].uniq - keys

        # pre-cache an entire tree
        tree_key = [tree, service, environment].compact.join("/")
        subtree = Cache.fetch(tree_key + '/', ttl: ttl) do
          result = @kv_client.get(tree_key, :recurse, :stale)
          result.values if result&.status == 200
        end
        populate_cache(tree_key, subtree, ttl)

        keys.each do |full_key|
          # these keys will have been populated (or not!) above; don't
          # actually try to fetch them
          result = Cache.fetch(full_key)
          return result if result
        end

        fallback_keys.each do |full_key|
          result = Cache.fetch(full_key, ttl: ttl) do
            result = @kv_client.get(full_key, :stale)
            result.values if result&.status == 200
          end
          return result if result
        end
        nil
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
      alias [] fetch

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
          kv_client: @kv_client,
          data_center: @data_center
        )
      end

      # Set multiple key value pairs
      #
      # @param kvs [Hash] Key value pairs where the hash key is the key
      #   and the hash value is the value
      # @param global [boolean] Is it a global key?
      # @return [Imperium::TransactionResponse]
      def set_keys(kvs, global: false)
        opts = @data_center.present? && global ? { dc: @data_center } : {}
        @kv_client.transaction(opts) do |tx|
          kvs.each { |k, v| tx.set(full_key(k, global: global), v) }
        end
      end

      private

      # Returns the full key
      #
      # @param key [String, Symbol] The key
      # @param global [boolean] Is it a global key?
      # @return [String] Full key
      def full_key(key, global: false)
        key_array = [tree, service, environment]
        if global
          key_array.prepend('global')
        else
          key_array << cluster
        end
        key_array.concat([prefix, key]).compact.join("/")
      end

      def populate_cache(prefix, subtree, ttl)
        if subtree.is_a?(Hash)
          subtree.each do |(k, v)|
            populate_cache("#{prefix}/#{k}", v, ttl)
          end
        else
          Cache.insert(prefix, subtree, ttl: ttl)
        end
      end
    end
  end
end
