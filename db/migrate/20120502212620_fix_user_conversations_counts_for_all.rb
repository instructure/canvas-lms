class FixUserConversationsCountsForAll < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    DataFixup::RecomputeUnreadConversationsCount.send_later_if_production(:run)
  end

  def self.down
    # The migration is non-destructive and only updates counts to reflect already existing data.
    #raise ActiveRecord::IrreversibleMigration
  end
end
