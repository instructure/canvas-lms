# frozen_string_literal: true

# Copyright (C) 2021 - present Instructure, Inc.
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

class AddFlagAuditorsCassandra < ActiveRecord::Migration[6.0]
  # Instructure won't be using any cassandra tables
  # for auditor changes to feature flags,
  # but some open source users may still be within the deprecation
  # window, so we'll include these tables so they can keep using
  # cassandra as a write target if they want until that gets remove.
  # TODO: When cassandra auditors are fully removed,
  # this migration can be deleted entirely.
  tag :predeploy

  include Canvas::Cassandra::Migration

  def self.cassandra_cluster
    'auditors'
  end

  def self.indexes
    %w(
      feature_flag_changes_by_feature_flag
    )
  end

  def self.up
    compression_params = cassandra.db.use_cql3? ?
        "WITH compression = { 'sstable_compression' : 'DeflateCompressor' }" :
        "WITH compression_parameters:sstable_compression='DeflateCompressor'"

    cassandra.execute %{
      CREATE TABLE feature_flags (
        id                    text PRIMARY KEY,
        created_at            timestamp,
        feature_flag_id       bigint,
        root_account_id       bigint,
        context_id            bigint,
        context_type          text,
        feature_name          text,
        event_type            text,
        state_before          text,
        state_after           text,
        user_id               bigint,
        request_id            text
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
    cassandra.execute %{DROP TABLE feature_flags;}
  end
end
