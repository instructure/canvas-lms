# frozen_string_literal: true

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

class Mutations::PostAssignmentGrades < Mutations::BaseMutation
  graphql_name "PostAssignmentGrades"

  argument :assignment_id, ID, required: true, prepare: GraphQLHelpers.relay_or_legacy_id_prepare_func("Assignment")
  argument :section_ids, [ID], required: false, prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func("Section")
  argument :only_student_ids, [ID], required: false, prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func("User")
  argument :skip_student_ids, [ID], required: false, prepare: GraphQLHelpers.relay_or_legacy_ids_prepare_func("User")
  argument :graded_only, Boolean, required: false

  field :assignment, Types::AssignmentType, null: true
  field :progress, Types::ProgressType, null: true
  field :sections, [Types::SectionType], null: true

  def resolve(input:)
    begin
      assignment = Assignment.find(input[:assignment_id])
      course = assignment.context
      sections = input[:section_ids] ? course.course_sections.where(id: input[:section_ids]) : nil
    rescue ActiveRecord::RecordNotFound
      raise GraphQL::ExecutionError, "not found"
    end

    verify_authorized_action!(assignment, :grade)

    unless assignment.grades_published?
      raise GraphQL::ExecutionError, "Assignments under moderation cannot be posted before grades are published"
    end
    raise GraphQL::ExecutionError, "Anonymous assignments cannot be posted by section" if sections && assignment.anonymous_grading?

    if input[:graded_only] && assignment.anonymous_grading
      raise GraphQL::ExecutionError, "Anonymous assignments cannot be posted by graded only"
    end

    if input[:only_student_ids] && input[:skip_student_ids]
      raise GraphQL::ExecutionError, I18n.t("{a} and {b} cannot be used together", a: "only_student_ids", b: "skip_student_ids")
    end

    visible_enrollments = course.apply_enrollment_visibility(course.student_enrollments, current_user, sections)
    visible_enrollments = visible_enrollments.where(user_id: input[:only_student_ids]) if input[:only_student_ids]
    visible_enrollments = visible_enrollments.where.not(user_id: input[:skip_student_ids]) if input[:skip_student_ids]

    submissions_scope = input[:graded_only] ? assignment.submissions.postable : assignment.submissions
    submissions_scope = submissions_scope.joins(user: :enrollments).merge(visible_enrollments)
    submission_ids = submissions_scope.pluck(:id)
    progress = course.progresses.new(tag: "post_assignment_grades")

    posting_params = {
      graded_only: !!input[:graded_only],
      section_names: sections&.pluck(:name)
    }

    if progress.save
      progress.process_job(
        assignment,
        :post_submissions,
        { preserve_method_args: true },
        progress:,
        submission_ids:,
        posting_params:,
        skip_content_participation_refresh: false
      )
      { assignment:, progress:, sections: }
    else
      raise GraphQL::ExecutionError, "Error posting assignment grades"
    end
  end
end
