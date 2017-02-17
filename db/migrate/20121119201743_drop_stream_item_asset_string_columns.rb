class DropStreamItemAssetStringColumns < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    remove_columns :stream_items, :context_code, :item_asset_string
    remove_column :stream_item_instances, :context_code
  end

  def self.down
    add_column :stream_item_instances, :context_code, :string
    add_column :stream_items, :context_code, :string
    add_column :stream_items, :item_asset_string, :string
  end
end
