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

module DataFixup::InvalidateBuiltInRoleCaches
  def self.run(klass, cache_type, start_at, end_at)
    klass.find_ids_in_ranges(start_at: start_at, end_at: end_at, batch_size: 10_000) do |min_id, max_id|
      # yes we'll end up clearing users multiple times but cross-shardedness makes this worse to try to do the other way around
      User.clear_cache_keys(klass.where(:id => min_id..max_id).distinct.pluck(:user_id), cache_type)
    end
  end
end
