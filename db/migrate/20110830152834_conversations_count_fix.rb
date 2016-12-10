class ConversationsCountFix < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    update "UPDATE #{ConversationParticipant.quoted_table_name} SET workflow_state = 'read' WHERE workflow_state = 'unread' AND last_message_at IS NULL"

    update <<-SQL
    UPDATE #{User.quoted_table_name}
    SET unread_conversations_count = (
      SELECT COUNT(*)
      FROM #{ConversationParticipant.quoted_table_name}
      WHERE workflow_state = 'unread'
        AND last_message_at IS NOT NULL
        AND user_id = users.id
    )
    SQL
  end

  def self.down
  end
end
