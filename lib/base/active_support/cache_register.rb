# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

module ActiveSupport
  module CacheRegister
    module Cache
      module Store
        # use this when you want to speed things up by avoiding extra redis calls to get the cache keys for a single object
        # and instead have it batch the reads and append them on, all in a (not-very-)fancy lua script
        # that all took way more effort for me to figure out than it was probably worth
        # but you're going to appreciate it now, dangit
        #
        # Example usage:
        # a call like
        #   Rails.cache.fetch(['key', user.cache_key(:enrollments), user.cache_key(:groups)].cache_key) { ... }
        # can be turned semi-equivalently (and more performantly) to:
        #   Rails.cache.fetch_with_batched_keys('key', batch_object: user, batched_keys: [:enrollments, :groups]}) { ... }
        #
        # NOTE: you won't be able to invalidate this directly using Rails.cache.delete
        # because of issues with the redis ring distribution (everything for batch_object is on the same node)
        # so you should just use clear_cache_key
        def fetch_with_batched_keys(key, batch_object:, batched_keys:, skip_cache_if_disabled: false, **opts, &block)
          batched_keys = Array(batched_keys)
          multi_types = batched_keys.select { |type| batch_object&.class&.prefer_multi_cache_for_key_type?(type) }
          if multi_types.any? && !::Rails.env.production?
            raise "fetch_with_batched_keys is not supported for multi-cache enabled key(s) - #{multi_types.join(", ")} on #{batch_object.class.name}"
          end

          if batch_object && !opts[:force] &&
             defined?(::ActiveSupport::Cache::RedisCacheStore) && is_a?(::ActiveSupport::Cache::RedisCacheStore) && Canvas::CacheRegister.enabled? &&
             batched_keys.all? { |type| batch_object.class.valid_cache_key_type?(type) }
            fetch_with_cache_register(key, batch_object, batched_keys, **opts, &block)
          elsif skip_cache_if_disabled
            yield # use for new caches that we're not already using updated_at+touch for
          else
            if batch_object # just fall back to the usual after appending to the key if needed
              key += (if Canvas::CacheRegister.enabled?
                        "/#{batched_keys&.map { |bk| batch_object.cache_key(bk) }&.join("/")}"
                      else
                        "/#{batch_object.cache_key}"
                      end)
            end
            fetch(key, opts, &block)
          end
        end

        private

        def fetch_with_cache_register(name, batch_object, batched_keys, **options, &)
          base_obj_key = batch_object.class.base_cache_register_key_for(batch_object)

          return yield unless base_obj_key

          options = merged_options(options)
          key = "#{normalize_key(name, options)}/{#{base_obj_key}}"

          entry = nil
          frd_key = nil

          redis = Canvas::CacheRegister.redis(base_obj_key, batch_object.shard)

          instrument(:read, name, options) do |payload|
            keys_to_batch = batched_keys.map { |type| "{#{base_obj_key}}/#{type}" }
            now = Time.now.utc.to_fs(batch_object.cache_timestamp_format)
            # pass in the base key, followed by the intermediate keys (that the script will pull and append to the base)
            keys = [key] + keys_to_batch
            ::Rails.logger.debug("Running redis read with batched keys - #{keys.join(", ")}")
            # get the entry (if it exists) as well as the full frd cache_key used (after batching in the register keys)
            # in case we need to write to it
            frd_key, cached_entry = failsafe :read_entry do
              Canvas::CacheRegister.lua.run(:get_with_batched_keys, keys, [now], redis)
            end

            cached_entry = Marshal.load(cached_entry) if cached_entry # rubocop:disable Security/MarshalLoad

            entry = handle_expired_entry(cached_entry, frd_key, options)
            if payload
              payload[:super_operation] = :fetch
              payload[:hit] = !!entry
            end
          end

          if entry
            get_entry_value(entry, name, **options)
          else
            result = instrument(:generate, name, **options, &)
            return result unless frd_key # we must have hit the failsafe above; we have no idea where to write to

            instrument(:write, name, **options) do
              entry = ::ActiveSupport::Cache::Entry.new(result, **options)
              failsafe :write_entry, returning: false do
                redis.set(frd_key, Marshal.dump(entry)) # write to the key generated in the lua script
              end
            end
            result
          end
        end
      end
    end
  end
end
