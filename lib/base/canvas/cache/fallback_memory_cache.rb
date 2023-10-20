# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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
  module Cache
    class FallbackMemoryCache < ActiveSupport::Cache::MemoryStore
      include FallbackExpirationCache

      def read_entry(key, **opts)
        super
      rescue TypeError => e
        if Rails.env.development? && e.message.include?("can't be referred to")
          Rails.logger.error("[LOCAL_CACHE] failed to deserialize value for key #{key}; deleting entry")
          delete_entry(key)
          return nil
        end
        raise
      end

      def clear(force: false)
        super
      end

      # lock is unique to this implementation, it's not a standard part of
      # rails caches.  Pass a key to lock and you'll get back a nonce if you
      # hold the lease.  You need to retain the nonce to unlock later, but the lock timeout
      # will make sure it gets released eventually.
      # This shadows the implementation in `SafeRedisRaceCondition`
      # so that we can use locking on any local cache implementation.
      def lock(key, options)
        nonce = SecureRandom.hex(20)
        lock_timeout = options.fetch(:lock_timeout, 5).to_i
        existing_value = read(key)
        return false if existing_value

        write(key, nonce, expires_in: lock_timeout.seconds)
        true
      end

      # unlock is unique to this implementation, it's not a standard part of
      # rails caches.  Pass a key to unlock and you'll get back a nonce if you
      # hold the lease.  It deletes the lock, but only if the nonce that
      # is passed.
      # This shadows the implementation in `SafeRedisRaceCondition`
      # so that we can use locking on any local cache implementation.
      def unlock(key, nonce)
        raise ArgumentError("nonce can't be nil") unless nonce

        existing_value = read(key)
        delete(key) if nonce == existing_value
      end
    end
  end
end
