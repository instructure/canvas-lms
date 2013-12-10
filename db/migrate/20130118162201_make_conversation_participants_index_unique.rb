class MakeConversationParticipantsIndexUnique < ActiveRecord::Migration
  disable_ddl_transaction!
  tag :predeploy

  def self.up
    add_index :conversation_participants, [:conversation_id, :user_id], :unique => true, :algorithm => :concurrently
    remove_index :conversation_participants, [:conversation_id]
  end

  def self.down
    add_index :conversation_participants, [:conversation_id]
    remove_index :conversation_participants, [:conversation_id, :user_id]
  end
end
