class AddCassandraGradeChangeExcused < ActiveRecord::Migration[4.2]
  tag :predeploy

  include Canvas::Cassandra::Migration

  def self.cassandra_cluster
    'auditors'
  end

  def self.up
    cassandra.execute %{ ALTER TABLE grade_changes ADD excused_before boolean; }
    cassandra.execute %{ ALTER TABLE grade_changes ADD excused_after boolean; }
  end

  def self.down
    cassandra.execute %{ ALTER TABLE grade_changes DROP excused_before; }
    cassandra.execute %{ ALTER TABLE grade_changes DROP excused_after; }
  end
end
