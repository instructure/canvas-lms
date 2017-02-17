class AddCassandraEventSourceToCoursesAuditor < ActiveRecord::Migration[4.2]
  tag :predeploy

  include Canvas::Cassandra::Migration

  def self.cassandra_cluster
    'auditors'
  end

  def self.up
    cassandra.execute %{ ALTER TABLE courses ADD event_source text; }
    cassandra.execute %{ ALTER TABLE courses ADD sis_batch_id bigint; }
  end

  def self.down
    cassandra.execute %{ ALTER TABLE courses DROP event_source; }
    cassandra.execute %{ ALTER TABLE courses DROP sis_batch_id; }
  end
end
