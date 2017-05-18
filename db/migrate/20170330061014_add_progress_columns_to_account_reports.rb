class AddProgressColumnsToAccountReports < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :account_reports, :current_line, :integer
    add_column :account_reports, :total_lines, :integer
  end
end
