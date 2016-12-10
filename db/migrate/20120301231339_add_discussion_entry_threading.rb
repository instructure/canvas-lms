class AddDiscussionEntryThreading < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :discussion_entries, :root_entry_id, :integer, :limit => 8
    add_column :discussion_entries, :depth, :integer
    add_index :discussion_entries, [:root_entry_id, :workflow_state, :created_at], :name => "index_discussion_entries_root_entry"
  end

  def self.down
    remove_column :discussion_entries, :depth
    remove_column :discussion_entries, :root_entry_id
  end
end
