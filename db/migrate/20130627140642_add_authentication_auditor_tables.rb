class AddAuthenticationAuditorTables < ActiveRecord::Migration[4.2]
  tag :predeploy

  include Canvas::Cassandra::Migration

  def self.cassandra_cluster
    'auditors'
  end

  def self.indexes
    %w(
      authentications_by_pseudonym
      authentications_by_account
      authentications_by_user
    )
  end

  def self.up
    compression_params = cassandra.db.use_cql3? ?
        "WITH compression = { 'sstable_compression' : 'DeflateCompressor' }" :
        "WITH compression_parameters:sstable_compression='DeflateCompressor'"

    cassandra.execute %{
      CREATE TABLE authentications (
        id                    text PRIMARY KEY,
        created_at            timestamp,
        pseudonym_id          bigint,
        account_id            bigint,
        user_id               bigint,
        event_type            text
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

    cassandra.execute %{DROP TABLE authentications;}
  end
end
