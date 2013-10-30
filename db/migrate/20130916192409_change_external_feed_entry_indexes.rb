class ChangeExternalFeedEntryIndexes < ActiveRecord::Migration
  tag :postdeploy
  self.transactional = false

  def self.up
    add_index :external_feed_entries, :external_feed_id, concurrently: true
    add_index :external_feed_entries, :uuid, concurrently: true
    add_index :external_feed_entries, :url, concurrently: true
    remove_index :external_feed_entries, name: 'external_feed_id_uuid'
    remove_index :external_feed_entries, [:asset_id, :asset_type]
  end

  def self.down
    remove_index :external_feed_entries, :external_feed_id
    remove_index :external_feed_entries, :uuid
    remove_index :external_feed_entries, :url
    add_index :external_feed_entries, [:external_feed_id, :uuid], concurrently: true, name: 'external_feed_id_uuid'
    add_index :external_feed_entries, [:asset_id, :asset_type], concurrently: true
  end
end
