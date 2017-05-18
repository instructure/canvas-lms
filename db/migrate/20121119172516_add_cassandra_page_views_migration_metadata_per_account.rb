#
# Copyright (C) 2012 - present Instructure, Inc.
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

class AddCassandraPageViewsMigrationMetadataPerAccount < ActiveRecord::Migration[4.2]
  tag :predeploy

  include Canvas::Cassandra::Migration

  def self.cassandra_cluster
    'page_views'
  end

  def self.up
    begin
      cassandra.execute("DROP TABLE page_views_migration_metadata")
    rescue CassandraCQL::Error::InvalidRequestException
      # this old table only exists in dev environments
    end

    cassandra.execute %{
      CREATE TABLE page_views_migration_metadata_per_account (
        shard_id         text,
        account_id       bigint,
        last_created_at  timestamp,
        last_request_id  text,
        PRIMARY KEY      (shard_id, account_id)
      )
    }
  end

  def self.down
    cassandra.execute %{
      DROP TABLE page_views_migration_metadata_per_account;
    }
  end
end
