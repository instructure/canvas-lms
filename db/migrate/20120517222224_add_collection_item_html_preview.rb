class AddCollectionItemHtmlPreview < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :collection_item_datas, :html_preview, :text
  end

  def self.down
    remove_column :collection_item_datas, :html_preview
  end
end
