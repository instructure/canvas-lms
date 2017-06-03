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

class ContextToConversationNotificationPreferences < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    if message = Notification.where(category: "Message", name: "Teacher Context Message").first
      if conversation_message = Notification.where(category: "Conversation Message").first
        execute <<-SQL
          INSERT INTO #{NotificationPolicy.quoted_table_name}
            (notification_id, user_id, communication_channel_id, broadcast, frequency)
            SELECT #{conversation_message.id}, user_id, communication_channel_id, broadcast, frequency
              FROM #{NotificationPolicy.quoted_table_name} WHERE notification_id=#{message.id};
        SQL
      end
      if added_to_conversation = Notification.where(category: "Added To Conversation").first
        execute <<-SQL
          INSERT INTO #{NotificationPolicy.quoted_table_name}
            (notification_id, user_id, communication_channel_id, broadcast, frequency)
            SELECT #{added_to_conversation.id}, user_id, communication_channel_id, broadcast, frequency
              FROM #{NotificationPolicy.quoted_table_name} WHERE notification_id=#{message.id}
        SQL
      end
    end
  end

  def self.down
  end
end
