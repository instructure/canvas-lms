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
class CreateAuditorsPartitions < ActiveRecord::Migration[5.2]
  tag :predeploy

  AUDITOR_CLASSES = [
    Auditors::ActiveRecord::AuthenticationRecord,
    Auditors::ActiveRecord::CourseRecord,
    Auditors::ActiveRecord::GradeChangeRecord
  ].freeze

  def up
    AUDITOR_CLASSES.each do |auditor_cls|
      partman = CanvasPartman::PartitionManager.create(auditor_cls)
      partman.create_initial_partitions
      current_partition_time = Time.zone.now
      Auditors::ActiveRecord::Partitioner.retention_months.times do
        # we're going to backfill these from cassandra, so let's create them now
        current_partition_time -= 1.send(auditor_cls.partitioning_interval)
        partman.create_partition(current_partition_time, graceful: true)
      end
    end
  end

  def down
    AUDITOR_CLASSES.each do |auditor_cls|
      partman = CanvasPartman::PartitionManager.create(auditor_cls)
      partman.partition_tables.each do |partition|
        drop_table partition
      end
    end
  end

end
