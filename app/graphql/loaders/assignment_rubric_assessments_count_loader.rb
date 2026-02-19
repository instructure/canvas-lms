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
#

class Loaders::AssignmentRubricAssessmentsCountLoader < GraphQL::Batch::Loader
  def perform(assignments)
    assignment_ids = assignments.map(&:id)

    # Single query with subqueries to count assessments
    # Only count assessments where:
    # 1. The user has a submission for that assignment
    # 2. The user has an active/completed enrollment in the assignment's course
    counts_by_assignment = RubricAssessment
                           .joins(:rubric_association)
                           .joins("INNER JOIN #{Assignment.quoted_table_name} a ON a.id = rubric_associations.association_id")
                           .where(rubric_associations: { association_type: "Assignment", association_id: assignment_ids })
                           .where(
                             "EXISTS (
          SELECT 1 FROM #{Submission.quoted_table_name} s
          WHERE s.assignment_id = rubric_associations.association_id
            AND s.user_id = #{RubricAssessment.quoted_table_name}.user_id
        )"
                           )
                           .where(
                             "EXISTS (
          SELECT 1 FROM #{Enrollment.quoted_table_name} e
          WHERE e.user_id = #{RubricAssessment.quoted_table_name}.user_id
            AND e.course_id = a.context_id
            AND e.type IN ('StudentEnrollment', 'StudentViewEnrollment')
            AND e.workflow_state IN ('active', 'completed')
        )"
                           )
                           .group("rubric_associations.association_id")
                           .count("#{RubricAssessment.quoted_table_name}.id")

    assignments.each { |assignment| fulfill(assignment, counts_by_assignment.fetch(assignment.id, 0)) }
  end
end
