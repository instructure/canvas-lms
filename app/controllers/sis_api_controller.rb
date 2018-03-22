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
# @model SisAssignment
#     {
#       "id": "SisAssignment",
#       "description": "Assignments that have post_to_sis enabled with other objects for convenience",
#       "properties": {
#         "id": {
#           "description": "The unique identifier for the assignment.",
#           "example": 4,
#           "type": "integer"
#         },
#         "course_id": {
#           "description": "The unique identifier for the course.",
#           "example": 6,
#           "type": "integer"
#         },
#         "name": {
#           "description": "the name of the assignment",
#           "example": "some assignment",
#           "type": "string"
#         },
#         "created_at": {
#           "description": "The time at which this assignment was originally created",
#           "example": "2012-07-01T23:59:00-06:00",
#           "type": "datetime"
#         },
#         "due_at": {
#           "description": "the due date for the assignment. returns null if not present. NOTE: If this assignment has assignment overrides, this field will be the due date as it applies to the user requesting information from the API.",
#           "example": "2012-07-01T23:59:00-06:00",
#           "type": "datetime"
#         },
#         "unlock_at": {
#           "description": "(Optional) Time at which this was/will be unlocked.",
#           "example": "2013-01-01T00:00:00-06:00",
#           "type": "datetime"
#         },
#         "lock_at": {
#           "description": "(Optional) Time at which this was/will be locked.",
#           "example": "2013-02-01T00:00:00-06:00",
#           "type": "datetime"
#         },
#         "points_possible": {
#           "description": "The maximum points possible for the assignment",
#           "example": 12,
#           "type": "integer"
#         },
#         "submission_types": {
#           "description": "the types of submissions allowed for this assignment list containing one or more of the following: 'discussion_topic', 'online_quiz', 'on_paper', 'none', 'external_tool', 'online_text_entry', 'online_url', 'online_upload' 'media_recording'",
#           "example": ["online_text_entry"],
#           "type": "array",
#           "items": {"type": "string"},
#           "allowableValues": {
#             "values": [
#               "discussion_topic",
#               "online_quiz",
#               "on_paper",
#               "not_graded",
#               "none",
#               "external_tool",
#               "online_text_entry",
#               "online_url",
#               "online_upload",
#               "media_recording"
#             ]
#           }
#         },
#         "integration_id": {
#             "example": "12341234",
#             "type": "string",
#             "description": "Third Party integration id for assignment"
#           },
#         "integration_data": {
#           "example": "other_data",
#           "type": "string",
#           "description": "(optional, Third Party integration data for assignment)"
#         },
#         "include_in_final_grade": {
#           "description": "If false, the assignment will be omitted from the student's final grade",
#           "example": true,
#           "type": "boolean"
#         },
#         "assignment_group": {
#           "description": "Includes attributes of a assignment_group for convenience. For more details see Assignments API.",
#           "type": "array",
#           "items": { "$ref": "AssignmentGroupAttributes" }
#         },
#         "sections": {
#           "description": "Includes attributes of a section for convenience. For more details see Sections API.",
#           "type": "array",
#           "items": { "$ref": "SectionAttributes" }
#         },
#         "user_overrides": {
#           "description": "Includes attributes of a user assignment overrides. For more details see Assignments API.",
#           "type": "array",
#           "items": { "$ref": "UserAssignmentOverrideAttributes" }
#         }
#       }
#     }
#
# @model AssignmentGroupAttributes
#     {
#       "id": "AssignmentGroupAttributes",
#       "description": "Some of the attributes of an Assignment Group. See Assignments API for more details",
#       "properties": {
#         "id": {
#           "description": "the id of the Assignment Group",
#           "example": 1,
#           "type": "integer"
#         },
#         "name": {
#           "description": "the name of the Assignment Group",
#           "example": "group2",
#           "type": "string"
#         },
#         "group_weight": {
#           "description": "the weight of the Assignment Group",
#           "example": 20,
#           "type": "integer"
#         },
#         "sis_source_id": {
#           "description": "the sis source id of the Assignment Group",
#           "example": "1234",
#           "type": "string"
#         },
#         "integration_data": {
#           "description": "the integration data of the Assignment Group",
#           "example": {"5678": "0954"},
#           "type": "object"
#         }
#       }
#     }
#
# @model SectionAttributes
#     {
#       "id": "SectionAttributes",
#       "description": "Some of the attributes of a section. For more details see Sections API.",
#       "properties": {
#         "id": {
#           "description": "The unique identifier for the section.",
#           "example": 1,
#           "type": "integer"
#         },
#         "name": {
#           "description": "The name of the section.",
#           "example": "Section A",
#           "type": "string"
#         },
#         "sis_id": {
#           "description": "The sis id of the section.",
#           "example": "s34643",
#           "type": "string"
#         },
#         "integration_id": {
#           "description": "Optional: The integration ID of the section.",
#           "example": "3452342345",
#           "type": "string"
#         },
#         "origin_course": {
#           "description": "The course to which the section belongs or the course from which the section was cross-listed",
#           "$ref": "CourseAttributes"
#         },
#         "xlist_course": {
#           "description": "Optional: Attributes of the xlist course. Only present when the section has been cross-listed. See Courses API for more details",
#           "$ref": "CourseAttributes"
#         },
#         "override": {
#           "description": "Optional: Attributes of the assignment override that apply to the section. See Assignment API for more details",
#           "$ref": "SectionAssignmentOverrideAttributes"
#         }
#       }
#     }
#
# @model CourseAttributes
#     {
#       "id": "CourseAttributes",
#       "description": "Attributes of a course object.  See Courses API for more details",
#       "properties": {
#         "id": {
#           "description": "The unique Canvas identifier for the origin course",
#           "example": 7,
#           "type": "integer"
#         },
#         "name": {
#           "description": "The name of the origin course.",
#           "example": "Section A",
#           "type": "string"
#         },
#         "sis_id": {
#           "description": "The sis id of the origin_course.",
#           "example": "c34643",
#           "type": "string"
#         },
#         "integration_id": {
#           "description": "The integration ID of the origin_course.",
#           "example": "I-2",
#           "type": "string"
#         }
#       }
#     }
#
# @model SectionAssignmentOverrideAttributes
#     {
#       "id": "SectionAssignmentOverrideAttributes",
#       "description": "Attributes of an assignment override that apply to the section object.  See Assignments API for more details",
#       "properties": {
#         "override_title": {
#           "description": "The title for the assignment override",
#           "example": "some section override",
#           "type": "string"
#         },
#         "due_at": {
#           "description": "the due date for the assignment. returns null if not present. NOTE: If this assignment has assignment overrides, this field will be the due date as it applies to the user requesting information from the API.",
#           "example": "2012-07-01T23:59:00-06:00",
#           "type": "datetime"
#         },
#         "unlock_at": {
#           "description": "(Optional) Time at which this was/will be unlocked.",
#           "example": "2013-01-01T00:00:00-06:00",
#           "type": "datetime"
#         },
#         "lock_at": {
#           "description": "(Optional) Time at which this was/will be locked.",
#           "example": "2013-02-01T00:00:00-06:00",
#           "type": "datetime"
#         }
#       }
#     }
#
# @model UserAssignmentOverrideAttributes
#     {
#       "id": "UserAssignmentOverrideAttributes",
#       "description": "Attributes of assignment overrides that apply to users.  See Assignments API for more details",
#       "properties": {
#         "id": {
#           "description": "The unique Canvas identifier for the assignment override",
#           "example": 218,
#           "type": "integer"
#         },
#         "title": {
#           "description": "The title of the assignment override.",
#           "example": "Override title",
#           "type": "string"
#         },
#         "due_at": {
#           "description": "The time at which this assignment is due",
#           "example": "2013-01-01T00:00:00-06:00",
#           "type": "datetime"
#         },
#         "unlock_at": {
#           "description": "(Optional) Time at which this was/will be unlocked.",
#           "example": "2013-01-01T00:00:00-06:00",
#           "type": "datetime"
#         },
#         "lock_at": {
#           "description": "(Optional) Time at which this was/will be locked.",
#           "example": "2013-02-01T00:00:00-06:00",
#           "type": "datetime"
#         },
#         "students": {
#           "description": "Includes attributes of a student for convenience. For more details see Users API.",
#           "type": "array",
#           "items": { "$ref": "StudentAttributes" }
#         }
#       }
#     }
#
# @model StudentAttributes
#     {
#       "id": "StudentAttributes",
#       "description": "Attributes of student.  See Users API for more details",
#       "properties": {
#         "user_id": {
#           "description": "The unique Canvas identifier for the user",
#           "example": 511,
#           "type": "integer"
#         },
#         "sis_user_id": {
#           "description": "The SIS ID associated with the user.  This field is only included if the user came from a SIS import and has permissions to view SIS information.",
#           "example": "SHEL93921",
#           "type": "string"
#         }
#       }
#     }
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
  #
  # Retrieve a list of published assignments flagged as "post_to_sis".
  # See the Assignments API for more details on assignments.
  # Assignment group and section information are included for convenience.
  #
  # Each section includes course information for the origin course and the
  # cross-listed course, if applicable. The `origin_course` is the course to
  # which the section belongs or the course from which the section was
  # cross-listed. Generally, the `origin_course` should be preferred when
  # performing integration work. The `xlist_course` is provided for consistency
  # and is only present when the section has been cross-listed.
  # See Sections API and Courses Api for me details.
  #
  # The `override` is only provided if the Differentiated Assignments course
  # feature is turned on and the assignment has an override for that section.
  # When there is an override for the assignment the override object's
  # keys/values can be merged with the top level assignment object to create a
  # view of the assignment object specific to that section.
  # See Assignments api for more information on assignment overrides.
  #
  # @argument account_id [Integer] The ID of the account to query.
  # @argument course_id [Integer] The ID of the course to query.
  #
  # @argument starts_before [DateTime, Optional] When searching on an account,
  # restricts to courses that start before this date (if they have a start date)
  # @argument ends_after [DateTime, Optional] When searching on an account,
  # restricts to courses that end after this date (if they have an end date)
  # @argument include [String, "student_overrides"] Array of additional
  # information to include.
  #
  #   "student_overrides":: returns individual student override information
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
      preload(context: {active_course_sections: [:nonxlist_course]})

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
