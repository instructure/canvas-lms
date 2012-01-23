class ConversationParticipantTags < ActiveRecord::Migration
  def self.up
    add_column :conversations, :tags, :text
    add_column :conversation_participants, :tags, :text
    add_column :conversation_message_participants, :tags, :text
  end

  def self.down
    remove_column :conversations, :tags
    remove_column :conversation_participants, :tags
    remove_column :conversation_message_participants, :tags
  end
end
