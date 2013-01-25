class AddIndexOnConversationMessagesAuthorId < ActiveRecord::Migration
  tag :postdeploy
  self.transactional = false

  def self.up
    add_index :conversation_messages, :author_id, :concurrent => true
  end

  def self.down
    remove_index :conversation_messages, :author_id
  end
end
