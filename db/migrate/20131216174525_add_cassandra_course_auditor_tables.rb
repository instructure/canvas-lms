class AddCassandraCourseAuditorTables < ActiveRecord::Migration[4.2]
  tag :predeploy

  include Canvas::Cassandra::Migration

  def self.cassandra_cluster
    'auditors'
  end

  def self.indexes
    %w(
      courses_by_course
    )
  end

  def self.up
    compression_params = cassandra.db.use_cql3? ?
        "WITH compression = { 'sstable_compression' : 'DeflateCompressor' }" :
        "WITH compression_parameters:sstable_compression='DeflateCompressor'"

    cassandra.execute %{
      CREATE TABLE courses (
        id                    text PRIMARY KEY,
        created_at            timestamp,
        request_id            text,
        course_id             bigint,
        event_type            text,
        user_id               bigint,
        data                  text
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

    cassandra.execute %{DROP TABLE courses;}
  end
end
