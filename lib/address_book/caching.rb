# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

module AddressBook

  # lets us keep a cache of results we've already looked up. so e.g. a bulk
  # fetch like known_users or search_users will fill this cache, and then when
  # making queries about individual users already included in that load, we
  # just reuse the cached value.
  module Caching
    class Cache
      def initialize
        @entries = {}
      end

      def key(recipient)
        Shard.global_id_for(recipient)
      end

      def null(users)
        users.each do |user|
          @entries[key(user)] = nil
        end
      end

      def store(user, common_courses, common_groups)
        @entries[key(user)] = {
          instance: user,
          common_courses: globalize(common_courses),
          common_groups: globalize(common_groups)
        }
      end

      def cached?(user)
        @entries.has_key?(key(user))
      end

      def fetch(user)
        entry = @entries[key(user)]
        entry && entry[:instance]
      end

      def common_courses(user)
        entry = @entries[key(user)]
        relativize(entry[:common_courses]) if entry
      end

      def common_groups(user)
        entry = @entries[key(user)]
        relativize(entry[:common_groups]) if entry
      end

      private
      def globalize(role_hash)
        Hash[*role_hash.map do |id,roles|
          id = Shard.global_id_for(id) if id > 0
          [id, roles]
        end.flatten(1)]
      end

      def relativize(role_hash)
        Hash[*role_hash.map do |id,roles|
          id = Shard.relative_id_for(id, Shard.current, Shard.current) if id > 0
          [id, roles]
        end.flatten(1)]
      end
    end

    def known_users(users, options={})
      uncached = users.select{ |user| !cached?(user) }
      # flag excluded users as "not known" so we don't recheck them
      # individually in the future
      @cache.null(uncached)
      # implementation is responsible for storing known users into cache
      super(uncached, options)
      users.map{ |user| @cache.fetch(user) }.compact
    end
  end
end
