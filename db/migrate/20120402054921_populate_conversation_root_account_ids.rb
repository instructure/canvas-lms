class PopulateConversationRootAccountIds < ActiveRecord::Migration
  tag :predeploy
  disable_ddl_transaction!

  def self.up
    DataFixup::PopulateConversationRootAccountIds.run
  end

  def self.down
    execute "UPDATE conversations SET root_account_ids = NULL"
  end
end