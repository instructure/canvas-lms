class MessageCounts < ActiveRecord::Migration
  def self.up
    add_column :conversation_participants, :message_count, :int, :default => 0
    execute <<-SQL
    UPDATE conversation_participants
    SET message_count = (
      SELECT COUNT(*)
      FROM conversation_messages, conversation_message_participants
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
