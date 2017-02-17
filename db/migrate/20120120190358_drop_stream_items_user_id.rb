class DropStreamItemsUserId < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    # it's been a long, long time since StreamItems were tied to users, that happens through StreamItemInstance now
    remove_column :stream_items, :user_id
  end

  def self.down
    add_column :stream_items, :user_id, :integer, :limit => 8
  end
end
