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

module Canvas
  module CacheRegister
    # this is an attempt to separate out more granular timestamps that we can use in cache keys
    # (that we'll actually store in redis itself)
    # instead of using a single almighty "updated_at" column that we constantly update
    # to invalidate caches (and end up invalidating almost everything)

    # e.g. `user.cache_key(:enrollments)` would be used for cache_keys that solely depend on a user's enrollments,
    # (such as in "Course#user_has_been_admin"), and then updated only when a user's enrollments are
    # (which is far less often than the many times per day users are currently being touched)

    ALLOWED_TYPES = {
      'Account' => %w{account_chain role_overrides global_navigation feature_flags brand_config default_locale
                      resolved_outcome_proficiency resolved_outcome_calculation_method},
      'Course' => %w{account_associations conditional_release},
      'User' => %w{enrollments groups account_users todo_list submissions user_services},
      'Assignment' => %w{availability conditional_release needs_grading},
      'Quizzes::Quiz' => %w{availability}
    }.freeze

    PREFER_MULTI_CACHE_TYPES = {
      'Account' => %w{feature_flags}
    }.freeze

    MIGRATED_TYPES = {}.freeze # for someday when we're reasonably sure we've moved all the cache keys for a type over

    def self.lua
      @lua ||= ::Redis::Scripting::Module.new(nil, File.join(File.dirname(__FILE__), "cache_register"))
    end

    def self.can_use_multi_cache_redis?
      MultiCache.cache.respond_to?(:redis) && !MultiCache.cache.redis.respond_to?(:node_for)
    end

    def self.redis(base_key, shard, prefer_multi_cache: false)
      if prefer_multi_cache && can_use_multi_cache_redis?
        return MultiCache.cache.redis
      end
      shard.activate do
        Canvas.redis.respond_to?(:node_for) ? Canvas.redis.node_for(base_key) : Canvas.redis
      end
    end

    def self.enabled?
       !::Rails.cache.is_a?(::ActiveSupport::Cache::NullStore) && Canvas.redis_enabled?
    end

    module ActiveRecord
      module Base
        module ClassMethods
          def base_cache_register_key_for(id_or_record)
            id = ::Shard.global_id_for(id_or_record)
            raise "invalid argument for cache clearing #{id}" if id && !id.is_a?(Integer) unless ::Rails.env.production?
            id && "cache_register/#{self.model_name.cache_key}/#{id}"
          end

          def valid_cache_key_type?(key_type)
            if CacheRegister::ALLOWED_TYPES[self.base_class.name]&.include?(key_type.to_s)
              true
            elsif ::Rails.env.production?
              false # fail gracefully
            else
              raise "invalid cache_key type '#{key_type}' for #{self.name}"
            end
          end

          def prefer_multi_cache_for_key_type?(key_type)
            !!CacheRegister::PREFER_MULTI_CACHE_TYPES[self.base_class.name]&.include?(key_type.to_s)
          end

          def skip_touch_for_type?(key_type)
            valid_cache_key_type?(key_type) &&
              CacheRegister::MIGRATED_TYPES[self.base_class.name]&.include?(key_type.to_s) &&
              Setting.get("revert_cache_register_migration_#{self.base_class.name.downcase}_#{key_type}", "false") != "true"
          end

          def touch_and_clear_cache_keys(ids_or_records, *key_types)
            unless key_types.all?{|type| self.skip_touch_for_type?(type)}
              Array(ids_or_records).sort.each_slice(1000) do |slice|
                self.where(id: slice).touch_all
              end
            end
            self.clear_cache_keys(ids_or_records, *key_types)
          end

          def clear_cache_keys(ids_or_records, *key_types)
            return unless key_types.all?{|type| valid_cache_key_type?(type)} && CacheRegister.enabled?

            multi_key_types, key_types = key_types.partition{|type| CacheRegister.can_use_multi_cache_redis? && self.prefer_multi_cache_for_key_type?(type)}

            ::Shard.partition_by_shard(Array(ids_or_records)) do |sharded_ids_or_records|
              base_keys = sharded_ids_or_records.map{|item| base_cache_register_key_for(item)}.compact
              return unless base_keys.any?
              if key_types.any?
                base_keys.group_by{|key| CacheRegister.redis(key, ::Shard.current)}.each do |redis, node_base_keys|
                  node_base_keys.map{|k| key_types.map{|type| "#{k}/#{type}"}}.flatten.each_slice(1000) do |slice|
                    redis.del(*slice)
                  end
                end
              end
              if multi_key_types.any?
                base_keys.each do |base_key|
                  multi_key_types.each do |type|
                    MultiCache.delete("#{base_key}/#{type}")
                  end
                end
              end
            end
          end

          # can be used to find the cache for an object by id alone

          # when calling directly, you should be prepared to handle a `nil` return value (and skip caching if so)
          # in the case that CacheRegister is disabled/reverted, since this would be preferable to
          # adding a possible N+1 trying to get the updated_at on the object
          # as such, this should only be used for places where we're adding new cache blocks,
          # and thus won't be terribly affected if the caching doesn't work
          def cache_key_for_id(id, key_type, skip_check: false)
            global_id = ::Shard.global_id_for(id)
            return nil unless skip_check || (global_id && self.valid_cache_key_type?(key_type) && CacheRegister.enabled?)

            base_key = self.base_cache_register_key_for(global_id)
            prefer_multi_cache = self.prefer_multi_cache_for_key_type?(key_type)
            redis = CacheRegister.redis(base_key, ::Shard.shard_for(global_id), prefer_multi_cache: prefer_multi_cache)
            full_key = "#{base_key}/#{key_type}"
            RequestCache.cache(full_key) do
              now = Time.now.utc.to_s(self.cache_timestamp_format)
              # try to get the timestamp for the type, set it to now if it doesn't exist
              ts = CacheRegister.lua.run(:get_key, [full_key], [now], redis)
              "#{self.model_name.cache_key}/#{global_id}-#{ts}"
            end
          end
        end

        def clear_cache_key(*key_types)
          self.class.clear_cache_keys(self, *key_types)
        end

        def cache_key(key_type=nil)
          return super() if key_type.nil? || self.new_record? ||
              !self.class.valid_cache_key_type?(key_type) || !CacheRegister.enabled?

          self.class.cache_key_for_id(self.global_id, key_type, skip_check: true)
        end
      end

      module Relation
        def clear_cache_keys(*key_types)
          klass.clear_cache_keys(self.pluck(klass.primary_key), *key_types)
        end

        def touch_and_clear_cache_keys(*key_types)
          klass.touch_and_clear_cache_keys(self.pluck(klass.primary_key), *key_types)
        end
      end
    end

    module ActiveSupport
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
            multi_types = batched_keys.select{|type| batch_object&.class&.prefer_multi_cache_for_key_type?(type)}
            if multi_types.any? && !::Rails.env.production?
              raise "fetch_with_batched_keys is not supported for multi-cache enabled key(s) - #{multi_types.join(", ")} on #{batch_object.class.name}"
            end

            if batch_object && !opts[:force] &&
                defined?(::ActiveSupport::Cache::RedisCacheStore) && self.is_a?(::ActiveSupport::Cache::RedisCacheStore) && CacheRegister.enabled? &&
                batched_keys.all?{|type| batch_object.class.valid_cache_key_type?(type)}
              fetch_with_cache_register(key, batch_object, batched_keys, opts, &block)
            else
              if skip_cache_if_disabled # use for new caches that we're not already using updated_at+touch for
                yield
              else
                if batch_object # just fall back to the usual after appending to the key if needed
                  key += (CacheRegister.enabled? ?
                    "/#{batched_keys&.map{|bk| batch_object.cache_key(bk)}.join("/")}" :
                    "/#{batch_object.cache_key}")
                end
                fetch(key, opts, &block)
              end
            end
          end

          private

          def fetch_with_cache_register(name, batch_object, batched_keys, options, &block)
            options = merged_options(options)
            key = normalize_key(name, options)
            key += "/#{batch_object.model_name.cache_key}/#{batch_object.id}"

            entry = nil
            frd_key = nil
            base_obj_key = batch_object.class.base_cache_register_key_for(batch_object)
            redis = CacheRegister.redis(base_obj_key, batch_object.shard)

            instrument(:read, name, options) do |payload|
              keys_to_batch = batched_keys.map{|type| "#{base_obj_key}/#{type}"}
              now = Time.now.utc.to_s(batch_object.cache_timestamp_format)
              # pass in the base key, followed by the intermediate keys (that the script will pull and append to the base)
              keys = [key] + keys_to_batch
              ::Rails.logger.debug("Running redis read with batched keys - #{keys.join(", ")}")
              # get the entry (if it exists) as well as the full frd cache_key used (after batching in the register keys)
              # in case we need to write to it
              frd_key, cached_entry = CacheRegister.lua.run(:get_with_batched_keys, keys, [now], redis)
              cached_entry = Marshal.load(cached_entry) if cached_entry

              entry = handle_expired_entry(cached_entry, frd_key, options)
              if payload
                payload[:super_operation] = :fetch
                payload[:hit] = !!entry
              end
            end

            if entry
              get_entry_value(entry, name, options)
            else
              result = instrument(:generate, name, options) { block.call }
              instrument(:write, name, options) do
                entry = ::ActiveSupport::Cache::Entry.new(result, **options)
                redis.set(frd_key, Marshal.dump(entry), options.merge(raw: true)) # write to the key generated in the lua script
              end
              result
            end
          end
        end
      end
    end
  end
end
