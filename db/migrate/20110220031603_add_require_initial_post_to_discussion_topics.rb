class AddRequireInitialPostToDiscussionTopics < ActiveRecord::Migration
  def self.up
    add_column :discussion_topics, :require_initial_post, :boolean
  end

  def self.down
    remove_column :discussion_topics, :require_initial_post
  end
end
