class StringColumnsToText < ActiveRecord::Migration
  def self.up
    change_column :error_reports, :url, :text
    change_column :error_reports, :message, :text
    change_column :content_tags, :url, :text
    change_column :page_views, :user_agent, :text
  end

  def self.down
    change_column :error_reports, :url, :string
    change_column :error_reports, :message, :string
    change_column :content_tags, :url, :string
    change_column :page_views, :user_agent, :string
  end
end
