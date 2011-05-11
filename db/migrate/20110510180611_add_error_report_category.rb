class AddErrorReportCategory < ActiveRecord::Migration
  def self.up
    add_column :error_reports, :category, :string
    add_index :error_reports, :category
  end

  def self.down
    remove_column :error_reports, :category
  end
end
