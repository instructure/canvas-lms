class RemoveCassandraPageViewsContributed < ActiveRecord::Migration[4.2]
  tag :postdeploy

  include Canvas::Cassandra::Migration

  def self.cassandra_cluster
    'page_views'
  end

  def self.runnable?
    # cassandra 1.2.x doesn't support dropping columns, oddly enough
    return false unless super
    server_version = cassandra.db.connection.describe_version()
    server_version < '19.35.0' || server_version >= '19.39.0'
  end

  def self.up
    cassandra.execute %{ ALTER TABLE page_views DROP contributed; }
  end

  def self.down
    cassandra.execute %{ ALTER TABLE page_views ADD contributed boolean; }
  end
end
