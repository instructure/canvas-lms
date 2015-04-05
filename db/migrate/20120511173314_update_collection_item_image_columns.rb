class UpdateCollectionItemImageColumns < ActiveRecord::Migration
  tag :predeploy

  # rubocop:disable Migration/RemoveColumn
  def self.up
    add_column :collection_item_datas, :image_pending, :boolean
    add_column :collection_item_datas, :image_attachment_id, :integer, :limit => 8
    add_column :collection_item_datas, :image_url, :text
    add_column :collection_items, :user_id, :integer, :limit => 8
    remove_column :collection_items, :image_attachment_id
    remove_column :collection_items, :image_url

    add_foreign_key :collection_items, :users
    add_foreign_key :collection_items, :collections
  end

  def self.down
    remove_column :collection_item_datas, :image_pending
    remove_column :collection_item_datas, :image_attachment_id
    remove_column :collection_item_datas, :image_url
    remove_column :collection_items, :user_id
    add_column :collection_items, :image_attachment_id, :integer, :limit => 8
    add_column :collection_items, :image_url, :text
  end
end
