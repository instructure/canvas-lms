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
    # all local cache implementations share a goal of being able to expire
    # cache entries before they're actually gone (think credentials expiring soon, etc),
    # but to hold onto the stale version just in case.
    #  This module provides some overrides that write all entries twice,
    # once with a prefix that never expires, so that it's possible to load
    # stale data in case of a connection failure.  This is usually done
    # with a begin/rescue block around the initial cache fetch
    # that puts a call to `fetch_without_expiration` in the rescue
    # clause
    module FallbackExpirationCache
      KEY_SUFFIX = '__no_expire'.freeze

      def fetch(*, expires_in: nil)
        return yield if expires_in == 0
        super
      end

      def fetch_without_expiration(key)
        fetch(key + KEY_SUFFIX)
      end

      private

      def write_entry(key, entry, options)
        if entry.value.nil?
          Rails.logger.warn("[LOCAL_CACHE] Writing nil value for key #{key}")
        end
        super(key, entry, options)
        forever_entry = entry.dup
        forever_entry.remove_instance_variable(:@expires_in)
        super(key + KEY_SUFFIX, forever_entry, options.except(:expires_in))
      end
    end
  end
end