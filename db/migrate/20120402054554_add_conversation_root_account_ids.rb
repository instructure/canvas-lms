class AddConversationRootAccountIds < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :conversations, :root_account_ids, :text
  end

  def self.down
    remove_column :conversations, :root_account_ids
  end
end
