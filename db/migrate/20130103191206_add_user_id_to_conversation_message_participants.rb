class AddUserIdToConversationMessageParticipants < ActiveRecord::Migration
  tag :predeploy
  self.transactional = false

  def self.up
    add_column :conversation_message_participants, :user_id, :integer, :limit => 8
    add_index :conversation_message_participants, [:user_id, :conversation_message_id], :name => "index_conversation_message_participants_on_uid_and_message_id", :unique => true, :concurrently => true
  end

  def self.down
    remove_index :conversation_message_participants, [:user_id, :conversation_message_id]
    remove_column :conversation_message_participants, :user_id
  end
end
