class RemoveCassandraPageViewsContributed < ActiveRecord::Migration
  tag :postdeploy

  include Canvas::Cassandra::Migration

  def self.cassandra_cluster
    'page_views'
  end

  def self.up
    cassandra.execute %{ ALTER TABLE page_views DROP contributed; }
  end

  def self.down
    cassandra.execute %{ ALTER TABLE page_views ADD contributed boolean; }
  end
end
