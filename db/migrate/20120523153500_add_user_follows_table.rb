class AddUserFollowsTable < ActiveRecord::Migration
  tag :predeploy

  def self.up
    create_table :user_follows do |t|
      t.integer :following_user_id, :limit => 8
      t.string  :followed_item_type
      t.integer :followed_item_id, :limit => 8

      t.timestamps
    end
    # unique index of things a user is following, searchable by thing type
    add_index :user_follows, [:following_user_id, :followed_item_type, :followed_item_id], :unique => true, :name => "index_user_follows_unique"
    # the reverse index -- users who are following this thing
    add_index :user_follows, [:followed_item_id, :followed_item_type], :name => "index_user_follows_inverse"
  end

  def self.down
    drop_table :user_follows
  end
end
