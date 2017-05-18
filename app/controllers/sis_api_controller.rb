#
# Copyright (C) 2015 - present Instructure, Inc.
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

# @API SIS Integration
#
# Includes helpers for integration with SIS systems.
#
class SisApiController < ApplicationController
  include Api::V1::SisAssignment

  before_action :require_view_all_grades, only: [:sis_assignments]
  before_action :require_grade_export, only: [:sis_assignments]
  before_action :require_published_course, only: [:sis_assignments]

  GRADE_EXPORT_NOT_ENABLED_ERROR = {
    code: 'not_enabled',
    error: 'A SIS integration is not configured and the bulk SIS Grade Export feature is not enabled'.freeze
  }.freeze

  COURSE_NOT_PUBLISHED_ERROR = {
    code: 'unpublished_course',
    error: 'Grade data is not available for non-published courses'.freeze
  }.freeze

  # @API Retrieve assignments enabled for grade export to SIS
  # @beta
  #
  # Retrieve a list of published assignments flagged as "post_to_sis". Assignment group and section information are
  # included for convenience.
  #
  # Each section includes course information for the origin course and the cross-listed course, if applicable. The
  # `origin_course` is the course to which the section belongs or the course from which the section was cross-listed.
  # Generally, the `origin_course` should be preferred when performing integration work. The `xlist_course` is provided
  # for consistency and is only present when the section has been cross-listed.
  #
  # The `override` is only provided if the Differentiated Assignments course feature is turned on and the assignment
  # has an override for that section. When there is an override for the assignment the override object's keys/values can
  # be merged with the top level assignment object to create a view of the assignment object specific to that section.
  #
  # @argument account_id [Integer] The ID of the account to query.
  # @argument course_id [Integer] The ID of the course to query.
  #
  # @argument starts_before [DateTime, Optional] When searching on an account, restricts to courses that start before
  #                                              this date (if they have a start date)
  # @argument ends_after [DateTime, Optional] When searching on an account, restricts to courses that end after this
  #                                              date (if they have an end date)
  # @argument include [String, "student_overrides"] Array of additional information to include.
  #
  #   "student_overrides":: returns individual student override information
  #
  # @example_response
  #   [
  #     {
  #       "id": 4,
  #       "course_id": 6,
  #       "name": "Assignment Title",
  #       "created_at": "2014-12-01T17:00:00Z",
  #       "due_at": "2015-01-01T17:00:00Z",
  #       "points_possible": 100,
  #       "integration_id": "IA-100",
  #       "submission_types": "["online_quiz"]",
  #       "integration_data": {
  #         "other_data": "values"
  #       },
  #       "include_in_final_grade": true,
  #       "assignment_group": {
  #         "id": 12,
  #         "name": "Assignments Group",
  #         "group_weight": 0.0,
  #         "sis_source_id": "abc123"
  #       }
  #       "sections": [
  #         {
  #           "id": 27,
  #           "name": "Section C2-S16",
  #           "sis_id": "C2-S16",
  #           "integration_id": "S-16",
  #           "origin_course": {
  #             "id": 2,
  #             "sis_id": "C2",
  #             "integration_id": "I-2"
  #           },
  #           "xlist_course": {
  #             "id": 6,
  #             "sis_id": "C6",
  #             "integration_id": "I-6"
  #           },
  #           "override": {
  #             "override_title": "Assignment Title",
  #             "due_at": "2015-02-01%17:00:00Z"
  #           }
  #         },
  #       ],
  #       "user_overrides": [
  #         {
  #           "id": 54351,
  #           "title": "Some Title",
  #           "due_at": "2017-02-08 22:11:10",
  #           "unlock_at": null,
  #           "lock_at": null,
  #           "students": [
  #             {
  #               "user_id": 643194
  #               "sis_user_id": SIS_123
  #             },
  #             {
  #               "user_id": 643195
  #               "sis_user_id": SIS_456
  #             }
  #           ]
  #         }
  #       ]
  #     },
  #
  #     ...
  #
  #   ]
  #
  def sis_assignments
    includes = {}
    includes[:student_overrides] = include_student_overrides?
    render json: sis_assignments_json(paginated_assignments, includes)
  end

  private

  def context
    @context ||=
      if params[:account_id]
        api_find(Account, params[:account_id])
      elsif params[:course_id]
        api_find(Course, params[:course_id])
      else
        fail ActiveRecord::RecordNotFound, 'unknown context type'
      end
  end

  def published_course_ids
    if context.is_a?(Account)
      course_scope = Course.published.where(account_id: [context.id] + Account.sub_account_ids_recursive(context.id))
      if starts_before = CanvasTime.try_parse(params[:starts_before])
        course_scope = course_scope.where("
        (courses.start_at IS NULL AND enrollment_terms.start_at IS NULL)
        OR courses.start_at < ? OR enrollment_terms.start_at < ?", starts_before, starts_before)
      end
      if ends_after = CanvasTime.try_parse(params[:ends_after])
        course_scope = course_scope.where("
        (courses.conclude_at IS NULL AND enrollment_terms.end_at IS NULL)
        OR courses.conclude_at > ? OR enrollment_terms.end_at > ?", ends_after, ends_after)
      end

      if starts_before || ends_after
        course_scope = course_scope.joins(:enrollment_term)
      end
      course_scope
    elsif context.is_a?(Course)
      [context.id]
    end
  end

  def include_student_overrides?
    params[:include].to_a.include?('student_overrides')
  end

  def published_assignments
    assignments = Assignment.published.
      where(post_to_sis: true).
      where(context_type: 'Course', context_id: published_course_ids).
      preload(:assignment_group).
      preload(context: { active_course_sections: [:nonxlist_course] })

    if include_student_overrides?
      assignments = assignments.preload(
        active_assignment_overrides: [assignment_override_students: [user: [:pseudonym]]]
      )
    else
      assignments = assignments.preload(:active_assignment_overrides)
    end

    assignments
  end

  def paginated_assignments
    Api.paginate(
      published_assignments.order(:context_id, :id),
      self,
      polymorphic_url([:sis, context, :assignments])
    )
  end

  def sis_grade_export_enabled?
    Assignment.sis_grade_export_enabled?(context)
  end

  def require_view_all_grades
    authorized_action(context, @current_user, :view_all_grades)
  end

  def require_grade_export
    render json: GRADE_EXPORT_NOT_ENABLED_ERROR, status: :bad_request unless sis_grade_export_enabled?
  end

  def require_published_course
    render json: COURSE_NOT_PUBLISHED_ERROR, status: :bad_request if context.is_a?(Course) && !context.published?
  end
end
