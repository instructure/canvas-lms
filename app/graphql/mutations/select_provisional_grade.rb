# frozen_string_literal: true

#
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
#

class Mutations::SelectProvisionalGrade < Mutations::BaseMutation
  argument :assignment_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Assignment")
  argument :provisional_grade_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("ModeratedGrading::ProvisionalGrade")

  field :provisional_grade, Types::ProvisionalGradeType, null: true

  def resolve(input:) # rubocop:disable GraphQL/UnusedArgument
    assignment_id = input[:assignment_id]
    provisional_grade_id = input[:provisional_grade_id]

    assignment = Assignment.active.find(assignment_id)
    raise GraphQL::ExecutionError, "not found" unless assignment.permits_moderation?(current_user)

    provisional_grade = assignment.provisional_grades.find(provisional_grade_id)
    student = provisional_grade.submission.user
    selection = ModeratedGrading::Selection.find_or_create_by!(assignment:, student:) do |s|
      s.selected_provisional_grade_id = provisional_grade.id
    end
    selection.update!(selected_provisional_grade_id: provisional_grade.id) unless selection.selected_provisional_grade_id == provisional_grade.id

    selection.create_moderation_event(current_user)

    { provisional_grade: }
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, "not found"
  end
end
