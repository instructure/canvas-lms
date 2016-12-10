class AddStreamItemInstancesIndex < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_index "stream_item_instances", ["stream_item_id"]
  end

  def self.down
    remove_index "stream_item_instances", ["stream_item_id"]
  end
end
