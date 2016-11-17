class AddPrivateHashToConversationParticipants < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def self.up
    add_column :conversation_participants, :private_hash, :string
    add_index :conversation_participants, [:private_hash, :user_id], :where => "private_hash IS NOT NULL", :unique => true, :algorithm => :concurrently
  end

  def self.down
    remove_column :conversation_participants, :private_hash
  end
end
