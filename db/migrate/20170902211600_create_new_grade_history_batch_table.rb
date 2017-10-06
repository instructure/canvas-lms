# Copyright (C) 2017 - present Instructure, Inc.
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
#

class CreateNewGradeHistoryBatchTable < ActiveRecord::Migration[4.2]
  tag :predeploy

  include Canvas::Cassandra::Migration

  LAST_BATCH_TABLE = DataFixup::InitNewGradeHistoryAuditLogIndexes::LAST_BATCH_TABLE

  def self.cassandra_cluster
    'auditors'
  end

  def self.up
    Rails.logger.debug("InitNewGradeHistoryAuditLogIndexes: #{LAST_BATCH_TABLE} exists? => #{table_exists?(cassandra, LAST_BATCH_TABLE)}")
    unless table_exists?(cassandra, LAST_BATCH_TABLE)
      compression_params = if cassandra.db.use_cql3?
        "WITH compression = { 'sstable_compression' : 'DeflateCompressor' }"
      else
        "WITH compression_parameters:sstable_compression='DeflateCompressor'"
      end

      create_table_command = %{
        CREATE TABLE #{LAST_BATCH_TABLE} (
          id int,
          last_id text,
          PRIMARY KEY (id)
        ) #{compression_params}
      }
      cassandra.execute(create_table_command)
    end
  end

  def self.down
    Rails.logger.debug("InitNewGradeHistoryAuditLogIndexes: #{LAST_BATCH_TABLE} exists? => #{table_exists?(cassandra, LAST_BATCH_TABLE)}")
    drop_table_command = "DROP TABLE #{LAST_BATCH_TABLE}"
    cassandra.execute(drop_table_command) if table_exists?(cassandra, LAST_BATCH_TABLE)
  end

  def self.table_exists?(cassandra, table)
    cql = %{
      SELECT *
      FROM #{table}
      LIMIT 1
    }
    cassandra.execute(cql)
    true
  rescue CassandraCQL::Error::InvalidRequestException
    false
  end
  private_class_method :table_exists?
end
