class AddPodcastOptionsToDiscussionTopics < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :discussion_topics, :podcast_enabled, :boolean
    add_column :discussion_topics, :podcast_has_student_posts, :boolean
  end

  def self.down
    remove_column :discussion_topics, :podcast_enabled
    remove_column :discussion_topics, :podcast_has_student_posts
  end
end
