class AddAccountIdToReportSnapshots < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :report_snapshots, :account_id, :integer, :limit => 8
  end

  def self.down
    remove_column :report_snapshots, :account_id
  end
end
