class PopulateConversationRootAccountIds < ActiveRecord::Migration
  tag :postdeploy
  self.transactional = false

  def self.up
    DataFixup::PopulateConversationRootAccountIds.send_later_if_production(:run)
  end

  def self.down
    execute "UPDATE conversations SET root_account_ids = NULL"
  end
end