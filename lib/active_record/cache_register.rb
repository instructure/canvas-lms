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

module ActiveRecord
  module CacheRegister
    module Base
      module ClassMethods
        def base_cache_register_key_for(id_or_record)
          id = ::Shard.global_id_for(id_or_record)
          raise "invalid argument for cache clearing #{id}" if id && !id.is_a?(Integer) && !Rails.env.production?

          id && "cache_register/#{self.model_name.cache_key}/#{id}"
        end

        def valid_cache_key_type?(key_type)
          if Canvas::CacheRegister::ALLOWED_TYPES[self.base_class.name]&.include?(key_type.to_s)
            true
          elsif ::Rails.env.production?
            false # fail gracefully
          else
            raise "invalid cache_key type '#{key_type}' for #{self.name}"
          end
        end

        def prefer_multi_cache_for_key_type?(key_type)
          !!Canvas::CacheRegister::PREFER_MULTI_CACHE_TYPES[self.base_class.name]&.include?(key_type.to_s)
        end

        def skip_touch_for_type?(key_type)
          valid_cache_key_type?(key_type) &&
            Canvas::CacheRegister::MIGRATED_TYPES[self.base_class.name]&.include?(key_type.to_s) &&
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
          return unless key_types.all?{|type| valid_cache_key_type?(type)} && Canvas::CacheRegister.enabled?

          multi_key_types, key_types = key_types.partition{|type| Canvas::CacheRegister.can_use_multi_cache_redis? && self.prefer_multi_cache_for_key_type?(type)}

          ::Shard.partition_by_shard(Array(ids_or_records)) do |sharded_ids_or_records|
            base_keys = sharded_ids_or_records.map{|item| base_cache_register_key_for(item)}.compact
            next if base_keys.empty?

            if key_types.any?
              base_keys.group_by{|key| Canvas::CacheRegister.redis(key, ::Shard.current)}.each do |redis, node_base_keys|
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
          return nil unless skip_check || (global_id && self.valid_cache_key_type?(key_type) && Canvas::CacheRegister.enabled?)

          base_key = self.base_cache_register_key_for(global_id)
          prefer_multi_cache = self.prefer_multi_cache_for_key_type?(key_type)
          redis = Canvas::CacheRegister.redis(base_key, ::Shard.shard_for(global_id), prefer_multi_cache: prefer_multi_cache)
          full_key = "#{base_key}/#{key_type}"
          RequestCache.cache(full_key) do
            now = Time.now.utc.to_s(self.cache_timestamp_format)
            # try to get the timestamp for the type, set it to now if it doesn't exist
            ts = Canvas::CacheRegister.lua.run(:get_key, [full_key], [now], redis)
            "#{self.model_name.cache_key}/#{global_id}-#{ts}"
          end
        end
      end

      def clear_cache_key(*key_types)
        self.class.clear_cache_keys(self, *key_types)
      end

      def cache_key(key_type=nil)
        return super() if key_type.nil? || self.new_record? ||
            !self.class.valid_cache_key_type?(key_type) || !Canvas::CacheRegister.enabled?

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
end
