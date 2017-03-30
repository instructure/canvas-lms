class ChangeDateFormatInAccountReports < ActiveRecord::Migration[4.2]
  tag :predeploy

  def cahnge
    remove_column :account_reports, :start_at, :date
    remove_column :account_reports, :end_at, :date
    add_column :account_reports, :start_at, :datetime
    add_column :account_reports, :end_at, :datetime
  end
end
