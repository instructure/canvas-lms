class FixUpNeedsGradingCounts < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    DataFixup::ResetUngradedCounts.send_later_if_production(:run)
  end

  def down
  end
end
