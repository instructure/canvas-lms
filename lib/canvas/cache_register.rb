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
      "Account" => %w[account_chain
                      role_overrides
                      global_navigation
                      feature_flags
                      brand_config
                      default_locale
                      resolved_outcome_proficiency
                      resolved_outcome_calculation_method],
      "Course" => %w[account_associations conditional_release],
      "User" => %w[enrollments groups account_users todo_list submissions user_services k5_user potential_unread_submission_ids],
      "AbstractAssignment" => %w[availability conditional_release needs_grading],
      "Assignment" => %w[availability conditional_release needs_grading],
      "Quizzes::Quiz" => %w[availability],
      "DiscussionTopic" => %w[availability],
      "WikiPage" => %w[availability]
    }.freeze

    PREFER_MULTI_CACHE_TYPES = {
      "Account" => %w[feature_flags]
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
  end
end
