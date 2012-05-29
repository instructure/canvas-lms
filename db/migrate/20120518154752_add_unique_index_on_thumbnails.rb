class AddUniqueIndexOnThumbnails < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_index :thumbnails, [:parent_id, :thumbnail], :unique => true, :name => "index_thumbnails_size"
  end

  def self.down
    remove_index :thumbnails, :name => "index_thumbnails_size"
  end
end
