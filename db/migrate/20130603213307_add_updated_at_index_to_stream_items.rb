class AddUpdatedAtIndexToStreamItems < ActiveRecord::Migration
  tag :predeploy
  disable_ddl_transaction!

  def self.up
    add_index :stream_items, :updated_at, :concurrently => true
  end

  def self.down
    remove_index :stream_items, :updated_at
  end
end
