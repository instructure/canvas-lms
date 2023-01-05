# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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
module DataFixup::PopulateQuotedEntry
  def self.run(start_at, end_at)
    DiscussionEntry.find_ids_in_ranges(start_at: start_at, end_at: end_at) do |min_id, max_id|
      DiscussionEntry.where(id: min_id..max_id, include_reply_preview: true).update_all("quoted_entry_id = parent_id")
    end
  end
end
