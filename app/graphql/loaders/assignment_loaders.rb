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
    class FinalGraderAnonymousIdLoader < GraphQL::Batch::Loader
      def perform(assignment_ids)
        moderation_graders = ModerationGrader
                             .joins("INNER JOIN #{Assignment.quoted_table_name} ON moderation_graders.assignment_id = assignments.id
                                          AND moderation_graders.user_id = assignments.final_grader_id")
                             .where(assignment_id: assignment_ids)
                             .pluck(:assignment_id, :anonymous_id)
                             .to_h

        assignment_ids.each { fulfill(it, moderation_graders[it]) }
      end
    end

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

    class OrderedModerationGradersWithSlotTakenLoader < GraphQL::Batch::Loader
      def perform(assignment_ids)
        moderation_graders_by_assignment = ModerationGrader
                                           .where(assignment_id: assignment_ids)
                                           .with_slot_taken
                                           .order(:anonymous_id)
                                           .group_by(&:assignment_id)

        assignment_ids.each do |id|
          fulfill(id, moderation_graders_by_assignment.fetch(id, []))
        end
      end
    end

    class GradedSubmissionsExistLoader < GraphQL::Batch::Loader
      def perform(assignment_ids)
        # Load only gradeable assignments (filter non-gradeable at database level)
        gradeable_assignments = AbstractAssignment.active
                                                  .where(id: assignment_ids)
                                                  .where.not(submission_types: ["not_graded", "wiki_page"])
                                                  .pluck(:id, :moderated_grading)
                                                  .to_h

        gradeable_assignment_ids = gradeable_assignments.keys

        # Fulfill non-gradeable assignments with false immediately
        assignment_ids.each do |id|
          unless gradeable_assignment_ids.include?(id)
            fulfill(id, false)
          end
        end

        # Early return if no gradeable assignments
        return if gradeable_assignment_ids.empty?

        # Get assignment IDs that have at least one graded submission
        # Using SELECT DISTINCT is much faster than COUNT(*) GROUP BY when we only need existence
        assignment_ids_with_graded = Submission
                                     .where(assignment_id: gradeable_assignment_ids)
                                     .graded
                                     .in_workflow_state("graded")
                                     .distinct
                                     .pluck(:assignment_id)
                                     .to_set

        # Check for provisional grades for moderated assignments
        provisional_grade_assignment_ids = Set.new
        moderated_assignment_ids = gradeable_assignments.select { |_id, moderated_grading| moderated_grading }.keys

        if moderated_assignment_ids.any?
          provisional_grade_assignment_ids = ModeratedGrading::ProvisionalGrade
                                             .joins(:submission)
                                             .where(submissions: { assignment_id: moderated_assignment_ids })
                                             .where.not(submissions: { submission_type: nil })
                                             .where.not(score: nil)
                                             .distinct
                                             .pluck("submissions.assignment_id")
                                             .to_set
        end

        # Process gradeable assignments
        gradeable_assignment_ids.each do |id|
          fulfill(id, assignment_ids_with_graded.include?(id) || provisional_grade_assignment_ids.include?(id))
        end
      end
    end
  end
end
