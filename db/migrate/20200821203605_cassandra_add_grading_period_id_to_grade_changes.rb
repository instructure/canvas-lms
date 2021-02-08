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

class CassandraAddGradingPeriodIdToGradeChanges < ActiveRecord::Migration[5.2]
  tag :predeploy

  include Canvas::Cassandra::Migration

  def self.cassandra_cluster
    'auditors'
  end

  def self.up
    unless cassandra_column_exists?('grade_changes', 'grading_period_id')
      cassandra.execute %{
        ALTER TABLE grade_changes
        ADD grading_period_id bigint;
      }
    end
  end

  def self.down
    if cassandra_column_exists?('grade_changes', 'grading_period_id')
      cassandra.execute %{
        ALTER TABLE grade_changes
        DROP grading_period_id;
      }
    end
  end
end
