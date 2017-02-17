class AddIndexOnConversationMessagesAuthorId < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_index :conversation_messages, :author_id, :algorithm => :concurrently
  end

  def self.down
    remove_index :conversation_messages, :author_id
  end
end
