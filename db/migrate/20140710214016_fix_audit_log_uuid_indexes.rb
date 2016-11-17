class FixAuditLogUuidIndexes < ActiveRecord::Migration[4.2]
  tag :postdeploy

  include Canvas::Cassandra::Migration

  MAPPING_TABLE = DataFixup::FixAuditLogUuidIndexes::MAPPING_TABLE
  LAST_BATCH_TABLE = DataFixup::FixAuditLogUuidIndexes::LAST_BATCH_TABLE

  def self.cassandra_cluster
    'auditors'
  end

  def self.up
    compression_params = cassandra.db.use_cql3? ?
      "WITH compression = { 'sstable_compression' : 'DeflateCompressor' }" :
      "WITH compression_parameters:sstable_compression='DeflateCompressor'"

    unless check_table_exists?(cassandra, MAPPING_TABLE)
      cql = %{
        CREATE TABLE #{MAPPING_TABLE} (
          record_type           text,
          id                    text,
          new_id                text,
          created_at            timestamp,
          PRIMARY KEY (record_type, id, created_at)
        ) #{compression_params}
      }

      cassandra.execute(cql)
    end

    unless check_table_exists?(cassandra, LAST_BATCH_TABLE)
      cql = %{
        CREATE TABLE #{LAST_BATCH_TABLE} (
          index_table           text,
          key                   text,
          ordered_id            text,
          batch_number          int,
          PRIMARY KEY (index_table)
        ) #{compression_params}
      }

      cassandra.execute(cql)
    end

    # Run Data Fixup
    DataFixup::FixAuditLogUuidIndexes::Migration.send_later_if_production(:run)
  end

  def self.down
    cassandra.execute("DROP TABLE #{MAPPING_TABLE}") if check_table_exists?(cassanrda, MAPPING_TABLE)
    cassandra.execute("DROP TABLE #{LAST_BATCH_TABLE}") if check_table_exists?(cassandra, LAST_BATCH_TABLE)
  end

  def self.check_table_exists?(cassandra, table)
    cql = %{
      SELECT *
      FROM #{table}
      LIMIT 1
    }

    begin
      cassandra.execute(cql)
      true
    rescue CassandraCQL::Error::InvalidRequestException
      false
    end
  end
end
