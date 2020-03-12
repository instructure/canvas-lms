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
#
module DataFixup::SplitUpUserPreferences
  def self.run(start_at, end_at)
    User.find_ids_in_ranges(:start_at => start_at, :end_at => end_at) do |min_id, max_id|
      User.where(:id => min_id..max_id).where("id < ? AND preferences IS NOT NULL", Shard::IDS_PER_SHARD).each do |u|
        if u.needs_preference_migration?
          u.migrate_preferences_if_needed
          u.save
        end
      end
    end
  end
end
