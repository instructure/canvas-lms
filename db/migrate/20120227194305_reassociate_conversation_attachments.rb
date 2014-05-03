class ReassociateConversationAttachments < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    DataFixup::ReassociateConversationAttachments.send_later_if_production(:run)
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
