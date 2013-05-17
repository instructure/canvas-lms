class AddCassandraPageViewsHttpMethod < ActiveRecord::Migration
  tag :predeploy

  include Canvas::Cassandra::Migration

  def self.cassandra_cluster
    'page_views'
  end

  def self.up
    cassandra.execute %{ ALTER TABLE page_views ADD http_method text; }
  end

  def self.down
    cassandra.execute %{ ALTER TABLE page_views DROP http_method; }
  end
end
