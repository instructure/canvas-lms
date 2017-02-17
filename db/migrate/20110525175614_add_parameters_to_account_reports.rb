class AddParametersToAccountReports < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :account_reports, :parameters, :text
  end

  def self.down
    remove_column :account_reports, :parameters
  end
end
