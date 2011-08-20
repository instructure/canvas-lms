class ContextToConversationNotificationPreferences < ActiveRecord::Migration
  def self.up
    if message = Notification.find_by_category_and_name("Message", "Teacher Context Message")
      if conversation_message = Notification.find_by_category("Conversation Message")
        execute <<-SQL
          INSERT INTO notification_policies
            (notification_id, user_id, communication_channel_id, broadcast, frequency)
            SELECT #{conversation_message.id}, user_id, communication_channel_id, broadcast, frequency
              FROM notification_policies WHERE notification_id=#{message.id};
        SQL
      end
      if added_to_conversation = Notification.find_by_category("Added To Conversation")
        execute <<-SQL
          INSERT INTO notification_policies
            (notification_id, user_id, communication_channel_id, broadcast, frequency)
            SELECT #{added_to_conversation.id}, user_id, communication_channel_id, broadcast, frequency
              FROM notification_policies WHERE notification_id=#{message.id}
        SQL
      end
    end
  end

  def self.down
  end
end
