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
