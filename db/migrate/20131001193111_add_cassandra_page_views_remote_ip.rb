class AddCassandraPageViewsRemoteIp < ActiveRecord::Migration
  tag :predeploy

  include Canvas::Cassandra::Migration

  def self.cassandra_cluster
    'page_views'
  end

  def self.up
    cassandra.execute %{ ALTER TABLE page_views ADD remote_ip text; }
  end

  def self.down
    cassandra.execute %{ ALTER TABLE page_views DROP remote_ip; }
  end
end
