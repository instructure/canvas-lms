class MakeConversationParticipantsIndexUnique < ActiveRecord::Migration
  self.transactional = false
  tag :predeploy

  def self.up
    add_index :conversation_participants, [:conversation_id, :user_id], :unique => true, :concurrently => true
    remove_index :conversation_participants, [:conversation_id]
  end

  def self.down
    add_index :conversation_participants, [:conversation_id]
    remove_index :conversation_participants, [:conversation_id, :user_id]
  end
end
