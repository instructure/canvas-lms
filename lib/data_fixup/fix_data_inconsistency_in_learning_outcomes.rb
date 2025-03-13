# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

module DataFixup
  module FixDataInconsistencyInLearningOutcomes
    def self.run
      Shard.find(4).activate do
        GuardRail.activate(:secondary) do
          ids = learning_outcomes_to_update
          GuardRail.activate(:primary) do
            delay_if_production(
              priority: Delayed::LOWER_PRIORITY,
              n_strand: "Datafix:FixDataInconsistencyInLearningOutcomes:UpdateLearningOutcome#{Shard.current.database_server.id}"
            ).update_learning_outcome(ids)
          end
        end
      end
    end

    def self.learning_outcomes_to_update
      ids = []
      LearningOutcome.where.not(data: nil).find_each(batch_size: 1000) do |record|
        rubric_criterion = record.data&.dig(:rubric_criterion)
        next unless rubric_criterion

        if rubric_criterion[:mastery_points].is_a?(String) || rubric_criterion[:points_possible].is_a?(String)
          ids.push(record.id)
        end
      end
      ids
    end

    def self.update_learning_outcome(ids)
      LearningOutcome.where(id: ids).find_each(batch_size: 1000) do |record|
        rubric_criterion = record.data[:rubric_criterion]
        rubric_criterion[:mastery_points] = rubric_criterion[:mastery_points].to_f if rubric_criterion[:mastery_points].is_a?(String)
        rubric_criterion[:points_possible] = rubric_criterion[:points_possible].to_f if rubric_criterion[:points_possible].is_a?(String)
        GuardRail.activate(:primary) { record.update_columns(data: record.data) }
      end
    end
  end
end
