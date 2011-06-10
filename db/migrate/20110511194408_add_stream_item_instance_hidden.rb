class AddStreamItemInstanceHidden < ActiveRecord::Migration
  def self.up
    add_column :stream_item_instances, :hidden, :boolean, :default => false, :null => false

    add_index :stream_item_instances, %w(user_id hidden id stream_item_id), :name => "index_stream_item_instances_global"
    add_index :stream_item_instances, %w(user_id context_code hidden id stream_item_id), :name => "index_stream_item_instances_context"
  end

  def self.down
    remove_column :stream_item_instances, :hidden
  end
end
