#
# Copyright (C) 2018 - present Instructure, Inc.
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

class Mutations::PostAssignmentGradesForSections < Mutations::BaseMutation
  graphql_name "PostAssignmentGradesForSections"

  argument :assignment_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Assignment")
  argument :section_ids, [ID], required: true, prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func("Section")

  field :assignment, Types::AssignmentType, null: true
  field :progress, Types::ProgressType, null: true
  field :sections, [Types::SectionType], null: true

  def resolve(input:)
    begin
      assignment = Assignment.find(input[:assignment_id])
      course = assignment.context
      sections = course.course_sections.where(id: input[:section_ids])
    rescue ActiveRecord::RecordNotFound
      raise GraphQL::ExecutionError, "not found"
    end

    verify_authorized_action!(assignment, :grade)
    raise GraphQL::ExecutionError, "Post Policies feature not enabled" unless course.feature_enabled?(:post_policies)

    unless assignment.grades_published?
      raise GraphQL::ExecutionError, "Assignments under moderation cannot be posted by section before grades are published"
    end
    raise GraphQL::ExecutionError, "Anonymous assignments cannot be posted by section" if assignment.anonymous_grading?

    if sections.empty? || sections.count != input[:section_ids].size
      raise GraphQL::ExecutionError, "Invalid section ids"
    end

    student_ids = course.student_enrollments.where(course_section: sections).pluck(:user_id)
    submission_ids = assignment.submissions.active.where(user_id: student_ids).pluck(:id)
    progress = course.progresses.new(tag: "post_assignment_grades_for_sections")

    if progress.save
      progress.process_job(assignment, :post_submissions, {preserve_method_args: true}, submission_ids: submission_ids)
      return {assignment: assignment, progress: progress, sections: sections}
    else
      raise GraphQL::ExecutionError, "Error posting assignment grades for sections"
    end
  end
end
