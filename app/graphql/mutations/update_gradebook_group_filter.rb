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
class Mutations::UpdateGradebookGroupFilter < Mutations::BaseMutation
  argument :anonymous_id, ID, required: false
  argument :assignment_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Assignment")
  argument :course_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Course")

  field :group_name, String, null: true
  field :reason_for_change, String, null: true
  def resolve(input:)
    verify_authorized_action!(current_user, :read)

    course_id = GraphQLHelpers.parse_relay_or_legacy_id(input[:course_id], "Course")
    course = Course.find(course_id)

    perms = %i[manage_grades view_all_grades]
    verify_any_authorized_actions!(course, perms)

    assignment_id = GraphQLHelpers.parse_relay_or_legacy_id(input[:assignment_id], "Assignment")
    anonymous_id = input[:anonymous_id]
    student_id = input[:anonymous_id].present? ? Submission.find_by(anonymous_id:, assignment_id:)&.user&.id : nil

    group_selection = SpeedGrader::StudentGroupSelection.new(current_user:, course:)
    updated_group_info = group_selection.select_group(student_id:)
    if updated_group_info[:group] != group_selection.initial_group
      new_group_id = updated_group_info[:group].present? ? updated_group_info[:group].id.to_s : nil
      context_settings = current_user.get_preference(:gradebook_settings, course.global_id) || {}
      context_settings.deep_merge!({
                                     "filter_rows_by" => {
                                       "student_group_ids" => new_group_id.present? ? [new_group_id] : []
                                     }
                                   })
      current_user.set_preference(:gradebook_settings, course.global_id, context_settings)
    end
    {
      group_name: updated_group_info[:group].present? ? updated_group_info[:group].name : nil,
      reason_for_change: updated_group_info[:reason_for_change],
    }
  rescue ActiveRecord::RecordNotFound
    raise GraphQL::ExecutionError, "not found"
  end
end
