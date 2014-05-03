class AddCassandraGradeChangeAuditorTables < ActiveRecord::Migration
 tag :predeploy

  include Canvas::Cassandra::Migration

  def self.cassandra_cluster
    'auditors'
  end

  def self.indexes
    %w(
      grade_changes_by_assignment
      grade_changes_by_course
      grade_changes_by_root_account_student
      grade_changes_by_root_account_grader
    )
  end

  def self.up
    compression_params = cassandra.db.use_cql3? ?
        "WITH compression = { 'sstable_compression' : 'DeflateCompressor' }" :
        "WITH compression_parameters:sstable_compression='DeflateCompressor'"

    cassandra.execute %{
      CREATE TABLE grade_changes (
        id                    text PRIMARY KEY,
        created_at            timestamp,
        request_id            text,
        account_id            bigint,
        submission_id         bigint,
        version_number        int,
        grader_id             bigint,
        student_id            bigint,
        assignment_id         bigint,
        context_id            bigint,
        context_type          text,
        event_type            text,
        grade_before          text,
        grade_after           text
      ) #{compression_params}}

    indexes.each do |index_name|
      cassandra.execute %{
        CREATE TABLE #{index_name} (
          key text,
          ordered_id text,
          id text,
          PRIMARY KEY (key, ordered_id)
        ) #{compression_params}}
    end
  end

  def self.down
    indexes.each do |index_name|
      cassandra.execute %{DROP TABLE #{index_name};}
    end

    cassandra.execute %{DROP TABLE grade_changes;}
  end
end
