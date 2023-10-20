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
module DynamicSettings
  class MemoryCache < ActiveSupport::Cache::MemoryStore
    def clear(force: false)
      super
    end

    def reset
      clear
    end

    # Everything from here down is actully a reimplementation
    # of some ideas that existed in the caching layer canvas proper.
    # That was a circular dependency, which we broke (kind of) by making this
    # part of the interface optional.
    # In the prefix proxy, if the caching implementation
    # does not respond to "fetch_without_expiration", it just raises any errors
    # it encounters, but if there IS such a method it will try to see if the value
    # is available in the non-expiring part of the cache.
    KEY_SUFFIX = "__no_expire"

    def fetch_without_expiration(key)
      fetch(key + KEY_SUFFIX)
    end

    private

    def write_entry(key, entry, **options)
      super(key, entry, **options)
      forever_entry = entry.dup
      forever_entry.remove_instance_variable(:@expires_in)
      super(key + KEY_SUFFIX, forever_entry, **options.except(:expires_in))
    end
  end
end
