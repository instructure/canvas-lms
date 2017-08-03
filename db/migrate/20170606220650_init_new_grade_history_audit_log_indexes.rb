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

class InitNewGradeHistoryAuditLogIndexes < ActiveRecord::Migration[4.2]
  tag :postdeploy

  include Canvas::Cassandra::Migration

  def self.cassandra_cluster
    'auditors'
  end

  def self.up
    DataFixup::InitNewGradeHistoryAuditLogIndexes.send_later_if_production_enqueue_args(
      :run, {
        priority: Delayed::LOW_PRIORITY,
        strand: "init_new_grade_history_audit_log_indexes:#{Shard.current.database_server.id}"
      }
    )
  end
end
