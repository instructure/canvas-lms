#
# Copyright (C) 2014 - present Instructure, Inc.
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
    #         from the block into the cache, along with how it got the value
    #         (:in_proc, :out_of_proc, :generated)
    #
    # key - The key to use for the cached object.
    # block - The block to call to get the value to write to the cache.
    #
    # Examples
    #
    #   fetch(:key) { 'value' }
    #   # => ['value', :in_proc]
    #
    # Returns the value of the cached object from the key.
    def self.fetch(key)
      return [yield, :bypass_generated] unless key

      value, how_it_got_it = self.read(key)
      if value.nil?
        if block_given?
          how_it_got_it = :generated
          elapsed = Benchmark.realtime do
            value = yield
          end
          Thread.current[:last_cache_generate] = elapsed # so we can record it in the logs
          self.write(key, value)
        end
      end

      [value, how_it_got_it]
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
      if @cache.key?(key)
        [@cache[key], :in_proc]
      else
        result = @cache[key] = Rails.cache.read(key)
        [result, :out_of_proc]
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
