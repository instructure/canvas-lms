# frozen_string_literal: true

# Copyright (C) 2025 - present Instructure, Inc.
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

module Loaders
  module AssignmentLoaders
    class HasRubricLoader < GraphQL::Batch::Loader
      def perform(assignment_ids)
        # Preload rubric associations for all assignments in the batch, using the 'active' scope
        active_ids = RubricAssociation
                     .active
                     .where(association_type: "Assignment", association_id: assignment_ids)
                     .pluck(:association_id)

        # Build a set for quick lookup
        active_set = active_ids.to_set

        # Fulfill each assignment_id with true/false (default to false if not found)
        assignment_ids.each do |id|
          fulfill(id, active_set.include?(id))
        end
      end
    end

    class PostManuallyLoader < GraphQL::Batch::Loader
      def perform(assignment_ids)
        assignments = Assignment
                      .where(id: assignment_ids)
                      .preload(:post_policy, context: :default_post_policy)
                      .index_by(&:id)

        assignment_ids.each do |id|
          assignment = assignments[id]
          value = if assignment&.post_policy
                    !!assignment.post_policy.post_manually
                  else
                    !!assignment&.course&.default_post_policy&.post_manually
                  end
          fulfill(id, value)
        end
      end
    end
  end
end
