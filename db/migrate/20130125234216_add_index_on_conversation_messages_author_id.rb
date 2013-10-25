class AddIndexOnConversationMessagesAuthorId < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_index :conversation_messages, :author_id, :algorithm => :concurrently
  end

  def self.down
    remove_index :conversation_messages, :author_id
  end
end
