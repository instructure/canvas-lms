# frozen_string_literal: true

# Copyright (C) 2020 - present Instructure, Inc.
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

class CassandraAddAccountIndexForCourses < ActiveRecord::Migration[5.2]
  tag :predeploy

  include Canvas::Cassandra::Migration

  def self.cassandra_cluster
    'auditors'
  end

  def self.up
    cassandra.execute %{
      ALTER TABLE courses
      ADD account_id bigint;
    } unless cassandra_column_exists?('courses', 'account_id')

    return if cassandra_table_exists?('courses_by_account')

    compression_params = if cassandra.db.use_cql3?
      "WITH compression = { 'sstable_compression' : 'DeflateCompressor' }"
    else
      "WITH compression_parameters:sstable_compression='DeflateCompressor'"
    end

    cassandra.execute %{
      CREATE TABLE courses_by_account (
        key text,
        ordered_id text,
        id text,
        PRIMARY KEY (key, ordered_id)
      ) #{compression_params}}
  end

  def self.down
    cassandra.execute %{
      ALTER TABLE courses
      DROP account_id;
    } if cassandra_column_exists?('courses', 'account_id')

    cassandra.execute %{DROP TABLE courses_by_account} if cassandra_table_exists?('courses_by_account')
  end
end
