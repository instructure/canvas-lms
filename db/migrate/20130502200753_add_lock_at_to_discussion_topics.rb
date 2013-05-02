class AddLockAtToDiscussionTopics < ActiveRecord::Migration
  tag :predeploy
  
  def self.up
    add_column :discussion_topics, :lock_at, :datetime
  end

  def self.down
    remove_column :discussion_topics, :lock_at
  end
end
