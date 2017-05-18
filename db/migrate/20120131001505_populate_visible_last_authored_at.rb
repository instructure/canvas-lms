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

class PopulateVisibleLastAuthoredAt < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    update <<-SQL
      UPDATE #{ConversationParticipant.quoted_table_name}
      SET visible_last_authored_at = (
        SELECT MAX(created_at)
        FROM #{ConversationMessage.quoted_table_name}, #{ConversationMessageParticipant.quoted_table_name}
        WHERE conversation_messages.conversation_id = conversation_participants.conversation_id
          AND conversation_messages.author_id = conversation_participants.user_id
          AND conversation_message_participants.conversation_message_id = conversation_messages.id
          AND conversation_message_participants.conversation_participant_id = conversation_participants.id
          AND NOT generated
      )
    SQL
  end

  def self.down
    update "UPDATE #{ConversationParticipant.quoted_table_name} SET visible_last_authored_at = NULL"
  end
end
