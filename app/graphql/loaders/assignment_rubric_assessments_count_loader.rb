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
    assignments.each { |assignment| fulfill(assignment, count_assessments(assignment)) }
  end

  def count_assessments(assignment)
    rubric_association = assignment.rubric_association
    return 0 unless rubric_association

    students = User.where(id: Submission.where(assignment_id: assignment.id).select(:user_id))
    return 0 unless students

    RubricAssessment.where(rubric_association:, user_id: students.pluck(:id)).count
  end
end
