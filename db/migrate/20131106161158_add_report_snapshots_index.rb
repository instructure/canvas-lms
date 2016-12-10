class AddReportSnapshotsIndex < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_index :report_snapshots, [:report_type, :account_id, :created_at], algorithm: :concurrently, name: 'index_on_report_snapshots'
  end

  def self.down
    remove_index :report_snapshots, name: 'index_on_report_snapshots'
  end
end
