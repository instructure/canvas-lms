class AddUniqueIndexToDiscussionTopics < ActiveRecord::Migration
  tag :postdeploy
  self.transactional = false

  def self.up
    case connection.adapter_name
    when 'PostgreSQL'
      execute <<-SQL
        CREATE UNIQUE INDEX CONCURRENTLY index_discussion_topics_unique_subtopic_per_context ON discussion_topics (context_id, context_type, root_topic_id);
      SQL
    else
      add_index :discussion_topics, [:context_id, :context_type, :root_topic_id], :unique => true, :name => "index_discussion_topics_unique_subtopic_per_context"
    end
    remove_index :discussion_topics, :name => "index_discussion_topics_on_context_id_and_context_type"
  end

  def self.down
    case connection.adapter_name
    when 'PostgreSQL'
      execute <<-SQL
        CREATE INDEX CONCURRENTLY index_discussion_topics_on_context_id_and_context_type ON discussion_topics (context_id, context_type);
      SQL
    else
      add_index :discussion_topics, [:context_id, :context_type], :name => "index_discussion_topics_on_context_id_and_context_type"
    end
    remove_index :discussion_topics, :name => "index_discussion_topics_unique_subtopic_per_context"
  end
end
