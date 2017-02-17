class AddCassandraGradedAnonymouslyToAuditorTables < ActiveRecord::Migration[4.2]
  tag :predeploy
  include Canvas::Cassandra::Migration

  def self.cassandra_cluster
    'auditors'
  end

  def self.up
    cassandra.execute %{
      ALTER TABLE grade_changes
      ADD graded_anonymously boolean
    }
  end

  def self.down
    cassandra.execute %{
      ALTER TABLE grade_changes
      DROP graded_anonymously
    }
  end
end
