class AddCollectionItemHtmlPreview < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :collection_item_datas, :html_preview, :text
  end

  def self.down
    remove_column :collection_item_datas, :html_preview
  end
end
