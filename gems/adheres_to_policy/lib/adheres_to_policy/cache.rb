#
# Copyright (C) 2014 Instructure, Inc.
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

module AdheresToPolicy
  class Cache
    # Internal: The time to live for the underlying cache.  In seconds.
    CACHE_EXPIRES_IN = 3600

    # Public: Gets the cached object with the provided key.  Will call the block
    #         if the key does not exist in the cache and store that returned value
    #         from the block into the cache.
    #
    # key - The key to use for the cached object.
    # block - The block to call to get the value to write to the cache.
    #
    # Examples
    #
    #   fetch(:key) { 'value' }
    #   # => 'value'
    #
    # Returns the value of the cached object from the key.
    def self.fetch(key, &block)
      return unless key

      unless value = self.read(key)
        if block
          value = block.call
          self.write(key, value)
        end
      end

      value
    end

    # Public: Writes an object to the cache with the provided key.  This also
    #         writes to the underlying Rails.cache.
    #
    # key - The key to use for the caching the object.
    # value - The value to cache.
    #
    # Examples
    #
    #   write(:key, 'value')
    #   # => 'value'
    #
    # Returns the value of the cached object from the key.
    def self.write(key, value)
      return unless key

      Rails.cache.write(key, value, expires_in: CACHE_EXPIRES_IN)
      @cache ||= {}
      @cache[key] = value
    end

    # Public: Reads an object from the cache with the provided key.  This also
    #         reads from the underlying Rails.cache if it is not in the local
    #         cached hash.
    #
    # key - The key to use for the caching the object.
    #
    # Examples
    #
    #   read(:key)
    #   # => 'value'
    #
    # Returns the value of the cached object from the key.
    def self.read(key)
      return unless key

      @cache ||= {}
      if @cache.has_key?(key)
        @cache[key]
      else
        @cache[key] = Rails.cache.read(key)
      end
    end

    # Public: Clears the local hashed cache.
    #
    # key - The key to clear.  If none is provided it will clear all keys.
    #
    # Examples
    #
    #   clear
    #   # => nil
    #
    #   clear(:key)
    #   # => 'value'
    #
    # Returns the value of the cached object from the key deleted.
    def self.clear(key = nil)
      if key
        @cache.delete(key)
      else
        @cache = nil
      end
    end
  end
end