class ContextToConversationNotificationPreferences < ActiveRecord::Migration
  def self.up
    if message = Notification.where(category: "Message", name: "Teacher Context Message").first
      if conversation_message = Notification.where(category: "Conversation Message").first
        execute <<-SQL
          INSERT INTO notification_policies
            (notification_id, user_id, communication_channel_id, broadcast, frequency)
            SELECT #{conversation_message.id}, user_id, communication_channel_id, broadcast, frequency
              FROM notification_policies WHERE notification_id=#{message.id};
        SQL
      end
      if added_to_conversation = Notification.where(category: "Added To Conversation").first
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
