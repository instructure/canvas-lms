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
    # A cache for values fetched from consul
    module Cache
      Value = Struct.new(:value, :expiration_time) do
        def expired?
          return false unless expiration_time
          Time.zone.now >= expiration_time
        end
      end

      # TODO: consider making this an L{R,f}U cache instead of a boundless one
      @store = {}

      class << self
        attr_reader :store
      end

      # Get the cached value, if any, from the store regardless of expiration
      #
      # This is really only meant as an emergency fallback in the event that
      # Consul can't be reached, not for normal operation.
      def self.fallback_fetch(key)
        @store[key]&.value
      end

      # Return the cached value for `key` or execute the supplied block to get it
      #
      # @param key [String] The key to cache the result under
      # @param ttl [ActiveSupport::Duration] The length of time this key should
      #   be cached for, pass nil for no expiration.
      def self.fetch(key, ttl: nil)
        stored = @store[key]
        if stored && !stored.expired?
          stored.expiration_time = ttl&.from_now if stored.expiration_time.nil?
          stored.value
        else
          return nil unless block_given?
          yield.tap do |value|
            insert(key, value, ttl: ttl) unless value.respond_to?(:not_found?) && value.not_found?
          end
        end
      end

      # Clear the cache store
      def self.reset!
        @store = {}
      end

      # Insert the supplied value into the cache using the supplied key
      #
      # @param key [String] The cache key to use
      # @param value [Object] The value to store
      # @param ttl [ActiveSupport::Duration] The length of time this key should
      #   be cached for, pass nil for no expiration.
      def self.insert(key, value, ttl: nil)
        @store[key] = Value.new(value, ttl&.from_now)
        value
      end
    end
  end
end
