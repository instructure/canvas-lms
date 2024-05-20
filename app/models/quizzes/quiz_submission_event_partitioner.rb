# frozen_string_literal: true

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

class Quizzes::QuizSubmissionEventPartitioner
  cattr_accessor :logger

  PRECREATE_TABLES = 2
  KEEP_MONTHS = 6

  def self.process(in_migration = false, prune: false)
    Shard.current.database_server.unguard do
      GuardRail.activate(:deploy) do
        log "*" * 80
        log "-" * 80

        partman = CanvasPartman::PartitionManager.create(Quizzes::QuizSubmissionEvent)

        partman.ensure_partitions(PRECREATE_TABLES)

        if prune
          Shard.current.database_server.unguard do
            partman.prune_partitions(KEEP_MONTHS)
          end
        end

        log "Done. Bye!"
        log "*" * 80
        unless in_migration || Rails.env.test?
          ActiveRecord::Base.connection_pool.disconnect!
        end
      end
    end
  end

  def self.prune
    process(prune: true)
  end

  def self.log(*args)
    logger&.info(*args)
  end

  def self.processed?
    partman = CanvasPartman::PartitionManager.create(Quizzes::QuizSubmissionEvent)
    partman.partitions_created?(PRECREATE_TABLES - 1)
  end
end
