class AddPinnedFlagToDiscussionTopics < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column 'discussion_topics', 'pinned', :boolean
  end

  def self.down
    remove_column 'discussion_topics', 'pinned'
  end
end
