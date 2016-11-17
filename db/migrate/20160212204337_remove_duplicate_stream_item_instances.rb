class RemoveDuplicateStreamItemInstances < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    DataFixup::RemoveDuplicateStreamItemInstances.run
    add_index :stream_item_instances, [:stream_item_id, :user_id], :unique => true, :algorithm => :concurrently
  end

  def down
    remove_index :stream_item_instances, [:stream_item_id, :user_id]
  end
end
