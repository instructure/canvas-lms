class DropOldStreamItemIndexes < ActiveRecord::Migration
  def self.up
    remove_index "stream_item_instances", :name => "index_stream_item_instances_with_context_code"
  end

  def self.down
    add_index "stream_item_instances", ["user_id", "context_code", "id", "stream_item_id"], :name => "index_stream_item_instances_with_context_code"
  end
end
