class ChangeExternalFeedEntryTitleToText < ActiveRecord::Migration
  tag :predeploy

  def self.up
    change_column :external_feed_entries, :title, :text
  end

  def self.down
    change_column :external_feed_entries, :title, :string
  end
end
