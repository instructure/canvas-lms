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

module DataFixup::ReintroduceDeletedEntriesToUnreadCount
  def self.run
    # Recalculate counts to include deleted entries
    DiscussionTopicParticipant.preload(:discussion_topic, :user).find_each do |participant|
      # since the previous code treated all deleted discussion entries as
      # hidden and not included in unread counts, we're going to update all
      # pre-existing deleted entries to be marked as read for all users
      #
      # and then the new behavior will only apply going forward
      topic = participant.discussion_topic
      topic.discussion_entries.deleted.each do |entry|
        entry.update_or_create_participant(:current_user => participant.user, :new_state => 'read')
      end

      # in theory this count won't need updating, but race conditions mean it
      # could be out of sync after the above, so we'll update it here. if it
      # doesn't change, the participant won't get re-saved
      read_count = topic.discussion_entry_participants.where(:user_id => participant.user_id, :workflow_state => "read").count
      participant.unread_entry_count = topic.discussion_entries.count - read_count
      participant.save
    end
  end
end
