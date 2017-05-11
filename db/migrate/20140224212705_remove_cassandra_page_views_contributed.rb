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

class RemoveCassandraPageViewsContributed < ActiveRecord::Migration[4.2]
  tag :postdeploy

  include Canvas::Cassandra::Migration

  def self.cassandra_cluster
    'page_views'
  end

  def self.runnable?
    # cassandra 1.2.x doesn't support dropping columns, oddly enough
    return false unless super
    server_version = cassandra.db.connection.describe_version()
    server_version < '19.35.0' || server_version >= '19.39.0'
  end

  def self.up
    cassandra.execute %{ ALTER TABLE page_views DROP contributed; }
  end

  def self.down
    cassandra.execute %{ ALTER TABLE page_views ADD contributed boolean; }
  end
end
