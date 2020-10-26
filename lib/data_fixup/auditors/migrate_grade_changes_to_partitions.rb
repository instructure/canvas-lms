# frozen_string_literal: true

#
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

module DataFixup::Auditors::MigrateGradeChangesToPartitions
  def self.run(batch_size: 1000, last_run_date_threshold: nil)
    partman = CanvasPartman::PartitionManager.create(::Auditors::ActiveRecord::GradeChangeRecord)
    if partman.migrate_data_to_partitions(timeout: 5.minutes, batch_size: batch_size)
      GuardRail.activate(:deploy) { Message.connection.update("TRUNCATE ONLY #{::Auditors::ActiveRecord::GradeChangeRecord.quoted_table_name}") }
    else
      self.requeue(batch_size: batch_size, last_run_date_threshold: last_run_date_threshold) # timed out
    end
  end

  def self.requeue(*args)
    self.send_later_if_production_enqueue_args(:run,
      {priority: Delayed::LOWER_PRIORITY,
      strand: "partition_auditors:#{Shard.current.database_server.id}"},
      *args)
  end
end