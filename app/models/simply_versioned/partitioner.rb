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

class SimplyVersioned::Partitioner
  cattr_accessor :logger

  PRECREATE_TABLES = 2

  def self.process
    Shard.current.database_server.unguard do
      GuardRail.activate(:deploy) do
        log "*" * 80
        log "-" * 80

        partman = CanvasPartman::PartitionManager.create(Version)

        partman.ensure_partitions(PRECREATE_TABLES)

        log "Done. Bye!"
        log "*" * 80
        unless Rails.env.test?
          ActiveRecord::Base.connection_pool.disconnect!
        end
      end
    end
  end

  def self.log(*args)
    logger&.info(*args)
  end

  def self.processed?
    partman = CanvasPartman::PartitionManager.create(Version)
    partman.partitions_created?(PRECREATE_TABLES - 1)
  end
end
