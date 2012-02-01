class PopulateVisibleLastAuthoredAt < ActiveRecord::Migration
  def self.up
    execute <<-SQL
      UPDATE conversation_participants
      SET visible_last_authored_at = (
        SELECT MAX(created_at)
        FROM conversation_messages, conversation_message_participants
        WHERE conversation_messages.conversation_id = conversation_participants.conversation_id
          AND conversation_messages.author_id = conversation_participants.user_id
          AND conversation_message_participants.conversation_message_id = conversation_messages.id
          AND conversation_message_participants.conversation_participant_id = conversation_participants.id
          AND NOT generated
      )
    SQL
  end

  def self.down
    execute "UPDATE conversation_participants SET visible_last_authored_at = NULL"
  end
end
