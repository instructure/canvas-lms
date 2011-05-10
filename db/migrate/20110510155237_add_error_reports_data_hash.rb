class AddErrorReportsDataHash < ActiveRecord::Migration
  def self.up
    add_column :error_reports, :data, :text
  end

  def self.down
    remove_column :error_reports, :data
  end
end
