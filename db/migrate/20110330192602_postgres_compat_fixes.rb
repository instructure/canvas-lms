class PostgresCompatFixes < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    change_column :attachments, :size, :bigint
    change_column :error_reports, :user_agent, :text
  end

  def self.down
    change_column :attachments, :size, :integer
    change_column :error_reports, :user_agent, :string
  end
end
