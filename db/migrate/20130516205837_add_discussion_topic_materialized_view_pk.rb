class AddDiscussionTopicMaterializedViewPk < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    case connection.adapter_name
    when 'PostgreSQL'
      # by pre-scanning the table, it's all in memory and adding the NOT NULL column constraint becomes really fast
      connection.select_value("SELECT COUNT(*) FROM discussion_topic_materialized_views")
      execute("ALTER TABLE discussion_topic_materialized_views ALTER discussion_topic_id SET NOT NULL")
      execute("ALTER TABLE discussion_topic_materialized_views ADD CONSTRAINT discussion_topic_materialized_views_pkey PRIMARY KEY USING INDEX index_discussion_topic_materialized_views")
    when 'MySQL', 'Mysql2'
      execute("ALTER TABLE discussion_topic_materialized_views ADD PRIMARY KEY (discussion_topic_id)")
      remove_index :discussion_topic_materialized_views, :name => 'index_discussion_topic_materialized_views'
    end
  end

  def self.down
    case connection.adapter_name
    when 'PostgreSQL'
      execute("ALTER TABLE discussion_topic_materialized_views DROP CONSTRAINT discussion_topic_materialized_views_pkey")
      execute("ALTER TABLE discussion_topic_materialized_views ALTER discussion_topic_id DROP NOT NULL")
      add_index :discussion_topic_materialized_views, :discussion_topic_id, :algorithm => :concurrently, :unique => true, :name => 'index_discussion_topic_materialized_views'
    when 'MySQL', 'Mysql2'
      execute("ALTER TABLE discussion_topic_materialized_views DROP PRIMARY KEY")
      add_index :discussion_topic_materialized_views, :discussion_topic_id, :algorithm => :concurrently, :unique => true, :name => 'index_discussion_topic_materialized_views'
    end
  end
end
