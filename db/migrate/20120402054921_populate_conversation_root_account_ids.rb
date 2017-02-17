class PopulateConversationRootAccountIds < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def self.up
    DataFixup::PopulateConversationRootAccountIds.run
  end

  def self.down
    Conversation.update_all(root_account_ids: nil)
  end
end
