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
#

# SafeRedisRaceCondition is for handling the case
# where some cache store needs to be able to "lock"
# when someone asks for a given entry that has expired so that we don't have
# multiple clients trying to do the same expensive regeneration.
# An example might be regenerating credentials from vault for a whole box to use;
# if 3 processes all find the current entry expired at the same time, you wouldn't
# want them all to independently re-generate credentials (unnecessary traffic for both
# vault and STS).
#
# This module assumes you are including it into something that eventually inherits from
# an ActiveSupport::Cache::RedisStore, and overrides methods in that internal
# implementation (depending on the existance of a redis client).
module ActiveSupport::Cache::SafeRedisRaceCondition
  # this is originally defined in ActiveSupport::Cache::Store,
  # and that implementation DOES handle race_condition_ttl by rewriting the
  # stale value back the cache with a slightly extended expiry.
  # It has no locking, though, so if the timing isn't quite right you can still get a few
  # processes regenerating at the same time.  This, instead, will ONLY override the method
  # if the race_condition_ttl is defined, and in that case it will
  # use a nonce as a lock value so it's easy to tell on unlock
  # whether the lease has been re-issued
  def handle_expired_entry(entry, key, options)
    @safe_redis_internal_options = {}
    return super unless options[:race_condition_ttl]

    lock_key = "lock:#{key}"

    if entry
      if entry.expired? && (lock_nonce = lock(lock_key, options))
        @safe_redis_internal_options[:lock_nonce] = lock_nonce
        @safe_redis_internal_options[:stale_entry] = entry
        return nil
      end
      # just return the stale value; someone else is busy
      # regenerating it
    else
      until entry
        if (lock_nonce = lock(lock_key, options))
          @safe_redis_internal_options[:lock_nonce] = lock_nonce
          break
        else
          # someone else is already generating it; wait for them
          sleep 0.1
          entry = read_entry(key, **options)
          next
        end
      end
    end
    entry
  end

  # this is originally defined in ActiveSupport::Cache::Store,
  # we only override it to make sure we can recover if
  # we have stale data available, and to make sure unlocking happens
  # no matter what (even if the block dies)
  def save_block_result_to_cache(name, options)
    super
  rescue => e
    raise unless @safe_redis_internal_options[:stale_entry]

    # if we have old stale data, silently swallow any
    # errors fetching fresh data, and return the stale entry
    Canvas::Errors.capture(e)
    @safe_redis_internal_options[:stale_entry].value
  ensure
    # only unlock if we have an actual lock nonce, not just "true"
    # that happens on failure
    if @safe_redis_internal_options[:lock_nonce].is_a?(String)
      key = normalize_key(name, options)
      unlock("lock:#{key}", @safe_redis_internal_options[:lock_nonce])
    end
  end

  # lock is unique to this implementation, it's not a standard part of
  # rails caches.  Pass a key to lock and you'll get back a nonce if you
  # hold the lease.  You need to retain the nonce to unlock later, but the lock timeout
  # will make sure it gets released eventually.
  def lock(key, options)
    nonce = SecureRandom.hex(20)
    lock_timeout = options.fetch(:lock_timeout, 5).to_i * 1000
    # redis failed for reasons unknown; say "true" that we locked, but the
    # nonce is useless
    failsafe :lock, returning: true do
      nonce if redis.set(key, nonce, px: lock_timeout, nx: true)
    end
  end

  # unlock is unique to this implementation, it's not a standard part of
  # rails caches.  Pass a key to unlock and you'll get back a nonce if you
  # hold the lease.  It deletes the lock, but only if the nonce that
  # is passed
  def unlock(key, nonce)
    raise ArgumentError, "nonce can't be nil" unless nonce

    node = redis
    node = redis.node_for(key) if redis.is_a?(Redis::Distributed)
    failsafe :unlock do
      delif_script.run(node, [key], [nonce])
    end
  end

  # redis does not have a built in "delete if", this lua script
  # is written to delete a key, but only if it's value matches the
  # provided value (so if someone else has re-written it since we won't delete it)
  def delif_script
    @delif_script ||= Redis::Scripting::Script.new(File.expand_path("delif.lua", __dir__))
  end

  # vanilla Rails is weird, and assumes "race_condition_ttl" is 5 minutes; override that to actually do math
  def write_entry(key, entry, unless_exist: false, raw: false, expires_in: nil, race_condition_ttl: nil, **options)
    if race_condition_ttl && expires_in
      expires_in += race_condition_ttl
      race_condition_ttl = nil
    end
    super
  end
end
