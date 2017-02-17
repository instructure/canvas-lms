class DropCollectionItemUserFk < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    # the user can be on another shard for group collections
    remove_foreign_key :collection_items, :users
  end

  def self.down
    add_foreign_key :collection_items, :users
  end
end
