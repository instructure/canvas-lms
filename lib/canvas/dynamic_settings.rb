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

require 'imperium'

module Canvas
  class DynamicSettings

    class Error < StandardError; end
    class ConsulError < Error; end

    CONSUL_READ_OPTIONS = %i{recurse stale}.freeze
    KV_NAMESPACE = "config/canvas".freeze

    class << self
      attr_accessor :config, :cache, :environment, :fallback_data

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
        end
      end

      def find(key, use_env: true)
        if config.nil?
          return fallback_data.fetch(key) if fallback_data.present?
          raise(ConsulError, "Unable to contact consul without config")
        else
          store_get(key, use_env: use_env)
        end
      end

      # settings found this way with nil expiry will be cached in the process
      # the first time they're asked for, and then can only be cleared with a SIGHUP
      # or restart of the process.  Make sure that's the behavior you want before
      # you use this method, or specify a timeout
      def from_cache(key, expires_in: nil, use_env: true)
        reset_cache! if cache.nil?
        cached_value = get_from_cache(key, expires_in)
        return cached_value if cached_value.present?
        # cache miss or timeout
        value = self.find(key, use_env: use_env)
        set_in_cache(key, value)
        value
      end

      def kv_client
        Imperium::KV.default_client
      end

      def reset_cache!(hard: false)
        @cache = {}
        @strategic_reserve = {} if hard
      end

      private

      def get_from_cache(key, timeout)
        return nil unless cache.key?(key)
        cache_entry = cache[key]
        return cache_entry[:value] if timeout.nil?
        threshold = (Time.zone.now - timeout).to_i
        return cache_entry[:value] if cache_entry[:timestamp] > threshold
      end

      def set_in_cache(key, value)
        cache[key] = {value: value, timestamp: Time.zone.now.to_i}
      end

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
