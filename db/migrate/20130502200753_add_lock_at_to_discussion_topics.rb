class AddLockAtToDiscussionTopics < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :discussion_topics, :lock_at, :datetime
  end

  def self.down
    remove_column :discussion_topics, :lock_at
  end
end
