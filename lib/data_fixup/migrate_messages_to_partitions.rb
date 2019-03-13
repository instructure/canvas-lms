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

module DataFixup::MigrateMessagesToPartitions
  def self.run
    weeks_to_keep = Setting.get("messages_partitions_keep_weeks", 52).to_i
    min_date_threshold = Time.now.utc.beginning_of_week - weeks_to_keep.weeks

    # remove all messages that would be inserted into a dropped partition
    while Message.from("ONLY #{Message.quoted_table_name}").
      where("created_at < ?", min_date_threshold).limit(1000).delete_all > 0
    end

    partman = CanvasPartman::PartitionManager.create(Message)

    unless partman.migrate_data_to_partitions(timeout: 5.minutes)
      self.requeue # timed out
    end
  end

  def self.requeue
    self.send_later_if_production_enqueue_args(:run,
      priority: Delayed::LOWER_PRIORITY,
      strand: "partition_messages:#{Shard.current.database_server.id}")
  end
end
