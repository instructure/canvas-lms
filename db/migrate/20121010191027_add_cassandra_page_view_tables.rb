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

class AddCassandraPageViewTables < ActiveRecord::Migration[4.2]
  tag :predeploy

  include Canvas::Cassandra::Migration

  def self.cassandra_cluster
    'page_views'
  end

  def self.up
    compression_params = cassandra.db.use_cql3? ?
        "WITH compression = { 'sstable_compression' : 'DeflateCompressor' }" :
        "WITH compression_parameters:sstable_compression='DeflateCompressor'"

    cassandra.execute %{
      CREATE TABLE page_views (
        request_id            text PRIMARY KEY,
        session_id            text,
        user_id               bigint,
        url                   text,
        context_id            bigint,
        context_type          text,
        asset_id              bigint,
        asset_type            text,
        controller            text,
        action                text,
        contributed           boolean,
        interaction_seconds   double,
        created_at            timestamp,
        updated_at            timestamp,
        developer_key_id      bigint,
        user_request          boolean,
        render_time           double,
        user_agent            text,
        asset_user_access_id  bigint,
        participated          boolean,
        summarized            boolean,
        account_id            bigint,
        real_user_id          bigint,
        http_method           text
      ) #{compression_params}}

    cassandra.execute %{
      CREATE TABLE page_views_history_by_context (
        context_and_time_bucket text,
        ordered_id text,
        request_id text,
        PRIMARY KEY (context_and_time_bucket, ordered_id)
      ) #{compression_params}}

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
      DROP TABLE page_views_history_by_context;
    }
    cassandra.execute %{
      DROP TABLE page_views;
    }
    cassandra.execute %{
      DROP TABLE page_views_migration_metadata_per_account;
    }
  end
end
