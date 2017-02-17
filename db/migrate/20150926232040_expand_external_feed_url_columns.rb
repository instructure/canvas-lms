class ExpandExternalFeedUrlColumns < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    change_column :external_feed_entries, :url, :text
    change_column :external_feed_entries, :source_url, :text
    change_column :external_feed_entries, :author_url, :text
  end

  def self.down
    change_column :external_feed_entries, :url, :string
    change_column :external_feed_entries, :source_url, :string
    change_column :external_feed_entries, :author_url, :string
  end
end
