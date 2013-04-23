class ChangeMigrationIssueStringsToText < ActiveRecord::Migration
  tag :predeploy

  def self.up
    change_column :migration_issues, :description, :text
    change_column :migration_issues, :error_message, :text
  end

  def self.down
    change_column :migration_issues, :description, :string
    change_column :migration_issues, :error_message, :string
  end
end
