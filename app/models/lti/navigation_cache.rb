#
# Copyright (C) 2011 - present Instructure, Inc.
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

module Lti
  class NavigationCache
    CACHE_KEY = 'navigation_tabs_key'

    def initialize(account)
      @account = account
    end

    def cache_key
      RequestCache.cache("account_navigation_cache_key", @account) do
        Rails.cache.fetch([@account, CACHE_KEY].cache_key) { SecureRandom.uuid }
      end
    end

    def invalidate_cache_key
      Rails.cache.delete([@account, CACHE_KEY].cache_key)
    end
  end
end
