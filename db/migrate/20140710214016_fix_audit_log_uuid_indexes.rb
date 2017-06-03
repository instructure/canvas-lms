#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

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
