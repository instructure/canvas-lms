class LengthenStringColumns < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    change_column :context_external_tools, :consumer_key, :text
    change_column :context_external_tools, :shared_secret, :text
    change_column :migration_issues, :fix_issue_html_url, :text
    change_column :submission_comments, :attachment_ids, :text
  end

  def self.down
    change_column :context_external_tools, :consumer_key, :string, :limit => 255
    change_column :context_external_tools, :shared_secret, :string, :limit => 255
    change_column :migration_issues, :fix_issue_html_url, :string, :limit => 255
    change_column :submission_comments, :attachment_ids, :string, :limit => 255
  end
end
