class AddUniqueIndexToDiscussionTopics < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_index :discussion_topics, [:context_id, :context_type, :root_topic_id], :unique => true, :algorithm => :concurrently, :name => "index_discussion_topics_unique_subtopic_per_context"
    remove_index :discussion_topics, :name => "index_discussion_topics_on_context_id_and_context_type"
  end

  def self.down
    add_index :discussion_topics, [:context_id, :context_type], :algorithm => :concurrently, :name => "index_discussion_topics_on_context_id_and_context_type"
    remove_index :discussion_topics, :name => "index_discussion_topics_unique_subtopic_per_context"
  end
end
