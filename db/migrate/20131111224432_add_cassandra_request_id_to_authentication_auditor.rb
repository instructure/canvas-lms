class AddCassandraRequestIdToAuthenticationAuditor < ActiveRecord::Migration
  tag :predeploy

  include Canvas::Cassandra::Migration

  def self.cassandra_cluster
    'auditors'
  end

  def self.up
    cassandra.execute %{ ALTER TABLE authentications ADD request_id text; }
  end

  def self.down
    cassandra.execute %{ ALTER TABLE authentications DROP request_id; }
  end
end
