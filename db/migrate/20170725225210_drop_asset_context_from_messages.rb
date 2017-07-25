class DropAssetContextFromMessages < ActiveRecord::Migration[5.0]
  tag :postdeploy

  def change
    remove_column :messages, :asset_context_id, :integer, limit: 8
    remove_column :messages, :asset_context_type, :string, limit: 255
    remove_column :delayed_notifications, :asset_context_id, :integer, limit: 8
    remove_column :delayed_notifications, :asset_context_type, :string, limit: 255
  end
end
