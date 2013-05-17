class AddCrocodocIdToUsers < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :users, :crocodoc_id, :int
    Setting.set('crocodoc_counter', 0) if Shard.current.default?
  end

  def self.down
    remove_column :users, :crocodoc_id
  end
end
