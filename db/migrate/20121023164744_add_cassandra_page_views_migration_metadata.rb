class AddCassandraPageViewsMigrationMetadata < ActiveRecord::Migration
  tag :predeploy

  include Canvas::Cassandra::Migration

  def self.cassandra_cluster
    'page_views'
  end

  def self.up
    cassandra.execute %{
      CREATE TABLE page_views_migration_metadata (
        shard_id         text,
        last_created_at  timestamp,
        last_request_id  text,
        PRIMARY KEY      (shard_id)
      )
    }
  end

  def self.down
    cassandra.execute %{
      DROP TABLE page_views_migration_metadata;
    }
  end
end
