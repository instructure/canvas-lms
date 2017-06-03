#
# Copyright (C) 2016 - present Instructure, Inc.
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

class AddCassandraGradeChangeScore < ActiveRecord::Migration[4.2]
  tag :predeploy

  include Canvas::Cassandra::Migration

  def self.cassandra_cluster
    'auditors'
  end

  def self.up
    cassandra.execute %{ ALTER TABLE grade_changes ADD score_before double; }
    cassandra.execute %{ ALTER TABLE grade_changes ADD score_after double; }
    cassandra.execute %{ ALTER TABLE grade_changes ADD points_possible_before double; }
    cassandra.execute %{ ALTER TABLE grade_changes ADD points_possible_after double; }
  end

  def self.down
    cassandra.execute %{ ALTER TABLE grade_changes DROP score_before; }
    cassandra.execute %{ ALTER TABLE grade_changes DROP score_after; }
    cassandra.execute %{ ALTER TABLE grade_changes DROP points_possible_before; }
    cassandra.execute %{ ALTER TABLE grade_changes DROP points_possible_after; }
  end
end
