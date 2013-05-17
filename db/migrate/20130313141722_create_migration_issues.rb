class CreateMigrationIssues < ActiveRecord::Migration
  tag :predeploy

  def self.up
    create_table :migration_issues do |t|
      t.integer :id, :limit => 8
      t.integer :content_migration_id, :limit => 8
      t.string :description
      t.string :workflow_state
      t.string :fix_issue_html_url
      t.string :issue_type
      t.integer :error_report_id, :limit => 8
      t.string :error_message

      t.timestamps
    end
    add_index :migration_issues, :content_migration_id
  end

  def self.down
    drop_table :migration_issues
  end
end
