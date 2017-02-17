class ChangeExternalFeedEntryIndexes < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_index :external_feed_entries, :external_feed_id, algorithm: :concurrently
    add_index :external_feed_entries, :uuid, algorithm: :concurrently
    add_index :external_feed_entries, :url, algorithm: :concurrently
    remove_index :external_feed_entries, name: 'external_feed_id_uuid'
    remove_index :external_feed_entries, [:asset_id, :asset_type]
  end

  def self.down
    remove_index :external_feed_entries, :external_feed_id
    remove_index :external_feed_entries, :uuid
    remove_index :external_feed_entries, :url
    add_index :external_feed_entries, [:external_feed_id, :uuid], algorithm: :concurrently, name: 'external_feed_id_uuid'
    add_index :external_feed_entries, [:asset_id, :asset_type], algorithm: :concurrently
  end
end
