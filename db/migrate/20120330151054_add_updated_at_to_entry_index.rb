class AddUpdatedAtToEntryIndex < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :discussion_topic_materialized_views, :generation_started_at, :timestamp
    add_index :discussion_entries, [:discussion_topic_id, :updated_at, :created_at], :name => "index_discussion_entries_for_topic"
    remove_index :discussion_entries, :name => "index_discussion_entries_on_discussion_topic_id"
  end

  def self.down
    remove_column :discussion_topic_materialized_views, :generation_started_at
    add_index :discussion_entries, [:discussion_topic_id], :name => "index_discussion_entries_on_discussion_topic_id"
    remove_index :discussion_entries, :name => "index_discussion_entries_for_topic"
  end
end
