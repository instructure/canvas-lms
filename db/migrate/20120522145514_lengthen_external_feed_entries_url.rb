class LengthenExternalFeedEntriesUrl < ActiveRecord::Migration
  tag :predeploy

  def self.up
    change_column :external_feed_entries, :url, :string, :limit => 4.kilobytes
  end

  def self.down
    change_column :external_feed_entries, :url, :string, :limit => 255
  end
end
