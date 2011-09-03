class ConversationsCountFix < ActiveRecord::Migration
  def self.up
    execute "UPDATE conversation_participants SET workflow_state = 'read' WHERE workflow_state = 'unread' AND last_message_at IS NULL"

    execute <<-SQL
    UPDATE users
    SET unread_conversations_count = (
      SELECT COUNT(*)
      FROM conversation_participants
      WHERE workflow_state = 'unread'
        AND last_message_at IS NOT NULL
        AND user_id = users.id
    )
    SQL
  end

  def self.down
  end
end
