class AddAccountReportsIndex < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :account_reports, [:account_id, :report_type, :updated_at], order: { updated_at: :desc }, algorithm: :concurrently, name: 'index_account_reports_latest_per_account'
  end
end
