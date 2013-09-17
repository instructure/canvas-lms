class AddLockedFlagToDiscussionTopics < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column 'discussion_topics', 'locked', :boolean
  end

  def self.down
    remove_column 'discussion_topics', 'locked'
  end
end
