class AddErrorReportsDataHash < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :error_reports, :data, :text
  end

  def self.down
    remove_column :error_reports, :data
  end
end
