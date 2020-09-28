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

      def clear(force: false)
        super
      end

      def write_set(hash, ttl: nil)
        opts = {expires_in: ttl}
        hash.each{|k, v| write(k, v, opts) }
      end
    end
  end
end