class AddLastReplyAtIndexToDiscussionTopics < ActiveRecord::Migration
  tag :predeploy
  disable_ddl_transaction!

  def self.up
    add_index :discussion_topics, [:context_id, :last_reply_at], :algorithm => :concurrently, :name => "index_discussion_topics_on_context_and_last_reply_at"
  end

  def self.down
    remove_index :discussion_topics, "index_discussion_topics_on_context_and_last_reply_at"
  end
end
