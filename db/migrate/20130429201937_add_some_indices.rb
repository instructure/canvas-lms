class AddSomeIndices < ActiveRecord::Migration
  tag :postdeploy
  self.transactional = false

  def self.up
    add_index :conversation_message_participants, :conversation_message_id, :name => "index_conversation_message_participants_on_message_id", :concurrently => true
    add_index :pseudonyms, :sis_communication_channel_id, :concurrently => true
  end

  def self.down
    remove_index :conversation_message_participants, :name => "index_conversation_message_participants_on_message_id"
    remove_index :pseudonyms, :sis_communication_channel_id
  end
end
