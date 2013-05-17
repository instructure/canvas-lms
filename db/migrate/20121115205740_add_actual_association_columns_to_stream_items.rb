class AddActualAssociationColumnsToStreamItems < ActiveRecord::Migration
  tag :predeploy
  self.transactional = false

  def self.up
    add_column :stream_items, :context_type, :string
    add_column :stream_items, :context_id, :integer, :limit => 8
    add_column :stream_items, :asset_type, :string
    add_column :stream_items, :asset_id, :integer, :limit => 8

    add_column :stream_item_instances, :context_type, :string
    add_column :stream_item_instances, :context_id, :integer, :limit => 8

    add_index :stream_items, [:asset_type, :asset_id], :unique => true, :concurrently => true
    add_index :stream_item_instances, [:context_type, :context_id], :concurrently => true
  end

  def self.down
    remove_columns :stream_item_instances, :context_type, :context_id
    remove_columns :stream_items, :context_type, :context_id, :asset_type, :asset_id
  end
end
