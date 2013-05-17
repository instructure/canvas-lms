class AddCassandraPageViewsMigrationMetadataPerAccount < ActiveRecord::Migration
  tag :predeploy

  include Canvas::Cassandra::Migration

  def self.cassandra_cluster
    'page_views'
  end

  def self.up
    begin
      cassandra.execute("DROP TABLE page_views_migration_metadata")
    rescue CassandraCQL::Error::InvalidRequestException
      # this old table only exists in dev environments
    end

    cassandra.execute %{
      CREATE TABLE page_views_migration_metadata_per_account (
        shard_id         text,
        account_id       bigint,
        last_created_at  timestamp,
        last_request_id  text,
        PRIMARY KEY      (shard_id, account_id)
      )
    }
  end

  def self.down
    cassandra.execute %{
      DROP TABLE page_views_migration_metadata_per_account;
    }
  end
end
