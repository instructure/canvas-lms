class AddAssetContextToDelayedNotification < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :delayed_notifications, :asset_context_type, :string
    add_column :delayed_notifications, :asset_context_id, :integer, :limit => 8
  end

  def self.down
    remove_column :delayed_notifications, :asset_context_id
    remove_column :delayed_notifications, :asset_context_type
  end
end
