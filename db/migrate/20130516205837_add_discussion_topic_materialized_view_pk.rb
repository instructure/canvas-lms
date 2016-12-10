class AddDiscussionTopicMaterializedViewPk < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    case connection.adapter_name
    when 'PostgreSQL'
      # by pre-scanning the table, it's all in memory and adding the NOT NULL column constraint becomes really fast
      DiscussionTopic::MaterializedView.count
      execute("ALTER TABLE #{DiscussionTopic::MaterializedView.quoted_table_name} ALTER discussion_topic_id SET NOT NULL")
      execute("ALTER TABLE #{DiscussionTopic::MaterializedView.quoted_table_name} ADD CONSTRAINT discussion_topic_materialized_views_pkey PRIMARY KEY USING INDEX index_discussion_topic_materialized_views")
    end
  end

  def self.down
    case connection.adapter_name
    when 'PostgreSQL'
      execute("ALTER TABLE #{DiscussionTopic::MaterializedView.quoted_table_name} DROP CONSTRAINT discussion_topic_materialized_views_pkey")
      execute("ALTER TABLE #{DiscussionTopic::MaterializedView.quoted_table_name} ALTER discussion_topic_id DROP NOT NULL")
      add_index :discussion_topic_materialized_views, :discussion_topic_id, :algorithm => :concurrently, :unique => true, :name => 'index_discussion_topic_materialized_views'
    end
  end
end
