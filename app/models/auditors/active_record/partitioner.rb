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

module Auditors::ActiveRecord
  class Partitioner
    cattr_accessor :logger

    AUDITOR_CLASSES = [
      AuthenticationRecord,
      CourseRecord,
      GradeChangeRecord,
      FeatureFlagRecord,
      PseudonymRecord
    ].freeze

    PRECREATE_TABLES = 2

    def self.process(prune: false)
      Shard.current.database_server.unguard do
        GuardRail.activate(:deploy) do
          AUDITOR_CLASSES.each do |auditor_cls|
            log "*" * 80
            log "-" * 80

            partman = CanvasPartman::PartitionManager.create(auditor_cls)

            partman.ensure_partitions(PRECREATE_TABLES)

            if prune
              Shard.current.database_server.unguard do
                partman.prune_partitions(retention_months)
              end
            end

            log "*" * 80
          end
          unless Rails.env.test?
            ActiveRecord::Base.connection_pool.disconnect!
          end
        end
      end
    end

    def self.prune
      process(prune: true)
    end

    def self.retention_months
      Setting.get("auditor_partitions_keep_months", 14).to_i
    end

    def self.log(*args)
      logger&.info(*args)
    end

    def self.processed?
      AUDITOR_CLASSES.all? do |auditor_cls|
        partman = CanvasPartman::PartitionManager.create(auditor_cls)
        partman.partitions_created?
      end
    end
  end
end
