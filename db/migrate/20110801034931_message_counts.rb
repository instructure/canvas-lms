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

class MessageCounts < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :conversation_participants, :message_count, :int, :default => 0
    update <<-SQL
    UPDATE #{ConversationParticipant.quoted_table_name}
    SET message_count = (
      SELECT COUNT(*)
      FROM #{ConversationMessage.quoted_table_name}, #{ConversationMessageParticipant.quoted_table_name}
      WHERE conversation_messages.conversation_id = conversation_participants.conversation_id
        AND NOT conversation_messages.generated
        AND conversation_messages.id = conversation_message_participants.conversation_message_id
        AND conversation_participant_id = conversation_participants.id
    )
    SQL
  end

  def self.down
    remove_column :conversation_participants, :message_count
  end
end
