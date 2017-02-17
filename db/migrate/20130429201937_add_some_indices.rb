class AddSomeIndices < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_index :conversation_message_participants, :conversation_message_id, :name => "index_conversation_message_participants_on_message_id", :algorithm => :concurrently
    add_index :pseudonyms, :sis_communication_channel_id, :algorithm => :concurrently
  end

  def self.down
    remove_index :conversation_message_participants, :name => "index_conversation_message_participants_on_message_id"
    remove_index :pseudonyms, :sis_communication_channel_id
  end
end
