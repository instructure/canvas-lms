class AddCassandraGradeChangeScore < ActiveRecord::Migration
  tag :predeploy

  include Canvas::Cassandra::Migration

  def self.cassandra_cluster
    'auditors'
  end

  def self.up
    cassandra.execute %{ ALTER TABLE grade_changes ADD score_before double; }
    cassandra.execute %{ ALTER TABLE grade_changes ADD score_after double; }
    cassandra.execute %{ ALTER TABLE grade_changes ADD points_possible_before double; }
    cassandra.execute %{ ALTER TABLE grade_changes ADD points_possible_after double; }
  end

  def self.down
    cassandra.execute %{ ALTER TABLE grade_changes DROP score_before; }
    cassandra.execute %{ ALTER TABLE grade_changes DROP score_after; }
    cassandra.execute %{ ALTER TABLE grade_changes DROP points_possible_before; }
    cassandra.execute %{ ALTER TABLE grade_changes DROP points_possible_after; }
  end
end
