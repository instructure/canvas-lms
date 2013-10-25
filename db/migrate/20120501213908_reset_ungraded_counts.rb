class ResetUngradedCounts < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    DataFixup::ResetUngradedCounts.send_later_if_production(:run)
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
