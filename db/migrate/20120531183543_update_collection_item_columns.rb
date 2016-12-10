class UpdateCollectionItemColumns < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    rename_column :collection_items, :description, :user_comment

    add_column :collection_item_datas, :title, :string
    add_column :collection_item_datas, :description, :text
  end

  def self.down
    rename_column :collection_items, :user_comment, :description

    remove_column :collection_item_datas, :title, :string
    remove_column :collection_item_datas, :description, :text
  end
end
