# frozen_string_literal: true

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

module DynamicSettings
  # A class for reading values from Consul
  #
  # @attr prefix [String] The prefix to be prepended to keys for querying.
  class PrefixProxy
    DEFAULT_TTL = 5.minutes
    # The TTL for cached values if none is specified in the constructor

    attr_reader :prefix, :tree, :service, :environment, :cluster, :retry_limit, :retry_base, :circuit_breaker
    attr_accessor :query_logging

    # Build a new prefix proxy
    #
    # @param prefix [String] The prefix to be prepended to keys for querying.
    # @param tree [String] Which tree to use (config, private, store)
    # @param service [String] The service name to use (i.e. who owns the configuration). Defaults to canvas
    # @param environment [String] An optional environment to look for so that multiple Canvas environments can share Consul
    # @param cluster [String] An optional cluster to override region or global settings
    # @param default_ttl [ActiveSupport::Duration] The TTL to use for cached
    #   values when not specified to the fetch methods.
    # @param data_center [String] Which regional datacenter to address for queries
    # @param query_logging [Boolean] when enabled (true), will output query logs and timing for each request
    def initialize(prefix = nil,
                   tree: :config,
                   service: :canvas,
                   environment: nil,
                   cluster: nil,
                   default_ttl: DEFAULT_TTL,
                   data_center: nil,
                   query_logging: true,
                   retry_limit: nil,
                   retry_base: nil,
                   circuit_breaker: nil)
      @prefix = prefix
      @tree = tree
      @service = service
      @environment = environment
      @cluster = cluster
      @default_ttl = default_ttl
      @data_center = data_center
      @query_logging = query_logging
      @retry_limit = retry_limit
      @retry_base = retry_base
      @circuit_breaker = circuit_breaker
    end

    def cache
      DynamicSettings.cache
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
    # @param failsafe_cache [false, PathInfo] Location on disk to store a
    #   failsafe cached for this value, in case Consul is down on a future boot.
    #   Should be used sparingly, since it will load a file off disk.
    # @return [String]
    # @return [nil] When no value was found
    def fetch(key, ttl: @default_ttl, failsafe_cache: false, **kwargs)
      unknown_kwargs = kwargs.keys - [:failsafe]
      raise ArgumentError, "unknown keyword(s): #{unknown_kwargs.map(&:inspect).join(", ")}" unless unknown_kwargs.empty?

      # Within a given request, no reason to talk to redis/consul multiple times for the same key in the same tree
      # The TTL is only relevant for the underlying cache-within a request we don't exceed the ttl boundary
      DynamicSettings.request_cache.cache(CACHE_KEY_PREFIX + full_key(key)) do
        fetch_without_request_cache(key, ttl:, failsafe_cache:, **kwargs)
      end
    end
    alias_method :[], :fetch

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
        tree:,
        service:,
        environment:,
        cluster:,
        default_ttl:,
        data_center: @data_center
      )
    end

    # Set multiple key value pairs
    #
    # @param kvs [Hash] Key value pairs where the hash key is the key
    #   and the hash value is the value
    # @param global [boolean] Is it a global key?
    # @return Consul txn response
    def set_keys(kvs, global: false)
      opts = (@data_center.present? && global) ? { dc: @data_center } : {}
      value = kvs.map do |k, v|
        {
          "KV" => {
            "Verb" => "set",
            "Key" => full_key(k, global:),
            "Value" => v,
          }
        }
      end
      Diplomat::Kv.txn(value, opts)
    end

    private

    def fetch_without_request_cache(key, ttl: @default_ttl, failsafe_cache: false, **kwargs)
      retry_count = 1
      failsafe_cache_file = failsafe_cache.join("#{key}.cached") if failsafe_cache

      keys = [
        full_key(key),
        [tree, service, environment, prefix, key].compact.join("/"),
      ].uniq

      fallback_keys = [
        [tree, service, prefix, key].compact.join("/"),
        full_key(key, global: true),
        ["global", tree, service, prefix, key].compact.join("/"),
      ].uniq - keys

      # try to get the local cache first right away
      keys.each do |full_key|
        result = cache.fetch(CACHE_KEY_PREFIX + full_key)
        return result if result
      end

      begin
        if circuit_breaker&.tripped?
          raise Diplomat::UnknownStatus, "Consul is unavailable because the circuit breaker has tripped"
        end

        # okay now pre-cache an entire tree
        tree_key = [tree, service, environment].compact.join("/")
        # This longer TTL is important for race condition for now.
        # if the tree JUST expired, we don't want to find
        # a valid tree, and then no valid subkeys, that makes
        # nils start popping up in the cache.  Subkeys should
        # last much longer than it takes to notice the tree key is
        # expired and trying to replace it.  When the tree writes
        # are fully atomic, this is much less of a concern,
        # we could have one ttl again
        subtree_ttl = ttl * 2
        cache.fetch(CACHE_KEY_PREFIX + tree_key + "/", expires_in: ttl) do
          values = kv_fetch(tree_key, recurse: true, stale: true)
          if values.nil?
            # no sense trying to populate the subkeys
            # when there's no tree
            nil
          else
            cache.write_multi(values.to_h { |kv| [CACHE_KEY_PREFIX + kv[:key], kv[:value]] }, ttl: subtree_ttl)
            values
          end
        end

        keys.each do |full_key|
          # these keys will have been populated (or not!) above
          cache_result = cache.fetch(CACHE_KEY_PREFIX + full_key, expires_in: subtree_ttl) do
            # this should rarely happen.  If we JUST populated the parent tree,
            # the value will already be in the cache.  If it's NOT in the tree, we'll cache
            # a nil (intentionally) and not hit this fetch over and over.  This protects us
            # from the race condition where we just expired and filled out the whole tree,
            # then the cache gets cleared, then we try to fetch one of the things we "know"
            # is in the cache now.  It's better to fall back to asking consul in those cases.
            # these values will still get overwritten the next time the parent tree expires,
            # and they'll still go away eventually if we REMOVE a key from a subtree in consul.
            kv_fetch(full_key, stale: true)
          end
          if cache_result
            check_cache(failsafe_cache_file, cache_result)
            return cache_result
          end
        end

        fallback_keys.each do |full_key|
          result = cache.fetch(CACHE_KEY_PREFIX + full_key, expires_in: ttl) do
            kv_fetch(full_key, stale: true)
          end
          if result
            check_cache(failsafe_cache_file, result)
            return result
          end
        end

        check_cache(failsafe_cache_file, nil)
      rescue Diplomat::KeyNotFound, Diplomat::UnknownStatus, Diplomat::PathNotFound, Faraday::ConnectionFailed, Errno::ECONNREFUSED => e
        if cache.respond_to?(:fetch_without_expiration)
          cache.fetch_without_expiration(CACHE_KEY_PREFIX + keys.first).tap do |val|
            if val
              DynamicSettings.on_fallback_recovery(e)
              return val
            end
          end
        end

        if retry_limit && retry_base && retry_count < retry_limit && !circuit_breaker&.tripped?
          # capture this to make sure that we have SOME
          # signal that the problem is continuing, even if our
          # retries are all successful.
          DynamicSettings.on_retry(e)

          backoff_interval = retry_base**retry_count
          retry_count += 1
          DynamicSettings.logger.warn("[DYNAMIC_SETTINGS] Consul error; retrying in #{backoff_interval} seconds...")
          sleep(backoff_interval)
          retry
        end

        # retries failed; trip the circuit breaker and avoid retries for some amount of time
        circuit_breaker&.trip unless circuit_breaker&.tripped?

        return YAML.safe_load_file(failsafe_cache_file) if failsafe_cache_file&.exist?
        return kwargs[:failsafe] if kwargs.key?(:failsafe)

        raise
      end
    end

    def check_cache(failsafe_cache_file, value)
      return unless failsafe_cache_file

      cache_exists = failsafe_cache_file.exist?
      cached_value = YAML.safe_load_file(failsafe_cache_file) if cache_exists

      failsafe_cache_file.write(YAML.dump(value)) if !cache_exists || cached_value != value
      value
    rescue Errno::EACCES
      # ignore permission errors
    end

    # bit of helper indirection
    # so that we can log actual
    # QUERIES (vs things fetched from the cache)
    # in one place, and process error states as actual
    # errors
    def kv_fetch(full_key, **options)
      result = nil
      error = nil
      method = options[:recurse] ? :get_all : :get
      ms = 1000 * Benchmark.realtime do
        result = Diplomat::Kv.send(method, full_key, options)
      rescue => e
        error = e
      end
      timing = format("CONSUL (%.2fms)", ms)
      status = "OK"
      unless error.nil?
        status = (error.is_a?(Diplomat::KeyNotFound) && error.message == full_key) ? "NOT_FOUND" : "ERROR"
      end
      DynamicSettings.logger.debug("  #{timing} get (#{full_key}) -> status:#{status}") if @query_logging
      return nil if status == "NOT_FOUND"
      raise error if error

      result
    end

    # Returns the full key
    #
    # @param key [String, Symbol] The key
    # @param global [boolean] Is it a global key?
    # @return [String] Full key
    def full_key(key, global: false)
      key_array = [tree, service, environment]
      if global
        key_array.prepend("global")
      else
        key_array << cluster
      end
      key_array.push(prefix, key).compact.join("/")
    end
  end
end
