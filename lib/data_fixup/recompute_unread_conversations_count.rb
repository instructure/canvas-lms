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

module DataFixup::RecomputeUnreadConversationsCount
  def self.run
    # Include "last_message_at IS NOT NULL" to prevent it from counting unread deleted messages.
    User.find_ids_in_batches do |ids|
      User.connection.execute(User.send(:sanitize_sql_array, [<<-SQL, ids]))
        UPDATE #{User.quoted_table_name} u SET unread_conversations_count = (
          SELECT COUNT(*)
          FROM #{ConversationParticipant.quoted_table_name} p
          WHERE p.workflow_state = 'unread'
            AND p.user_id = u.id
            AND p.last_message_at IS NOT NULL
        )
        WHERE id IN (?)
      SQL
    end
  end
end