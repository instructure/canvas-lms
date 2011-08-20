class UnreadCounts < ActiveRecord::Migration
  def self.up
    add_column :users, :unread_conversations_count, :int, :default => 0
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
    remove_column :users, :unread_conversations_count
  end
end
