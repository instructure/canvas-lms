#
# Copyright (C) 2012 - present Instructure, Inc.
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

module DataFixup::ExcludeDeletedEntriesFromUnreadCount
  def self.run
    # Deleted all partipant entries for deleted discussion entries
    DiscussionEntryParticipant.
        joins(:discussion_entry).preload(:discussion_entry).readonly(false).
        where(:discussion_entries => { :workflow_state => 'deleted' }).
        destroy_all

    # Recalculate counts based on active entries minus read entries
    DiscussionTopicParticipant.preload(:discussion_topic).find_each do |participant|
      topic = participant.discussion_topic
      read_count = topic.discussion_entry_participants.where(:user_id => participant.user_id, :workflow_state => "read").count
      participant.unread_entry_count = topic.discussion_entries.active.count - read_count
      participant.save
    end
  end
end
