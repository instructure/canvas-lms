# frozen_string_literal: true

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
  def self.run(batch_size: 1000, last_run_date_threshold: nil)
    weeks_to_keep = Setting.get("messages_partitions_keep_weeks", 52).to_i
    min_date_threshold = Time.now.utc.beginning_of_week - weeks_to_keep.weeks

    # don't re-run the deletion if we don't need to
    unless last_run_date_threshold && last_run_date_threshold >= min_date_threshold
      # remove all messages that would be inserted into a dropped partition
      while Message.from("ONLY #{Message.quoted_table_name}").
        where("created_at < ?", min_date_threshold).limit(1000).delete_all > 0
      end
    end

    partman = CanvasPartman::PartitionManager.create(Message)

    if partman.migrate_data_to_partitions(timeout: 5.minutes, batch_size: batch_size)
      GuardRail.activate(:deploy) { Message.connection.update("TRUNCATE ONLY #{Message.quoted_table_name}") }
    else
      self.requeue(batch_size: batch_size, last_run_date_threshold: min_date_threshold) # timed out
    end
  end

  def self.requeue(*args)
    delay_if_production(priority: Delayed::LOWER_PRIORITY,
      strand: "partition_messages:#{Shard.current.database_server.id}").run(*args)
  end
end
