# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

class Loaders::RootEntryParticipantCountsLoader < GraphQL::Batch::Loader
  def initialize(current_user:)
    @current_user = current_user
  end

  def perform(root_entries)
    counts = DiscussionEntryParticipant.joins(:discussion_entry).
      where(discussion_entry_id: DiscussionEntry.where(root_entry_id: root_entries), user_id: @current_user).
      group('root_entry_id', 'discussion_entry_participants.workflow_state').count

    root_entries.each do |entry|
      fulfill(entry, nil) if entry.root_entry_id
      count_values = {}
      count_values["unread_count"] = (counts[[entry.id, "unread"]] || 0)
      count_values["replies_count"] = count_values["unread_count"] + (counts[[entry.id, "read"]] || 0)
      fulfill(entry, count_values)
    end
  end
end
