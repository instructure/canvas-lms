#
# Copyright (C) 2013 Instructure, Inc.
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

# @API Grade Change Log
#
# Query audit log of grade change events.
#
# Only available if the server has configured audit logs; will return 404 Not
# Found response otherwise.
#
# For each endpoint, a compound document is returned. The primary collection of
# event objects is paginated, ordered by date descending. Secondary collections
# of assignments, courses, students and graders related to the returned events
# are also included. Refer to the Assignment, Courses, and Users APIs for
# descriptions of the objects in those collections.
#
# @model GradeChangeEventLinks
#     {
#       "id": "GradeChangeEventLinks",
#       "description": "",
#       "properties": {
#         "assignment": {
#           "description": "ID of the assignment associated with the event",
#           "example": 2319,
#           "type": "integer"
#         },
#         "course": {
#           "description": "ID of the course associated with the event. will match the context_id in the associated assignment if the context type for the assignment is a course",
#           "example": 2319,
#           "type": "integer"
#         },
#         "student": {
#           "description": "ID of the student associated with the event. will match the user_id in the associated submission.",
#           "example": 2319,
#           "type": "integer"
#         },
#         "grader": {
#           "description": "ID of the grader associated with the event. will match the grader_id in the associated submission.",
#           "example": 2319,
#           "type": "integer"
#         },
#         "page_view": {
#           "description": "ID of the page view during the event if it exists.",
#           "example": "e2b76430-27a5-0131-3ca1-48e0eb13f29b",
#           "type": "string"
#         }
#       }
#     }
#
# @model GradeChangeEvent
#     {
#       "id": "GradeChangeEvent",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "ID of the event.",
#           "example": "e2b76430-27a5-0131-3ca1-48e0eb13f29b",
#           "type": "string"
#         },
#         "created_at": {
#           "description": "timestamp of the event",
#           "example": "2012-07-19T15:00:00-06:00",
#           "type": "datetime"
#         },
#         "event_type": {
#           "description": "GradeChange event type",
#           "example": "grade_change",
#           "type": "string"
#         },
#         "grade_after": {
#           "description": "The grade after the change.",
#           "example": "8",
#           "type": "string"
#         },
#         "grade_before": {
#           "description": "The grade before the change.",
#           "example": "8",
#           "type": "string"
#         },
#         "version_number": {
#           "description": "Version Number of the grade change submission.",
#           "example": "1",
#           "type": "string"
#         },
#         "request_id": {
#           "description": "The unique request id of the request during the grade change.",
#           "example": "e2b76430-27a5-0131-3ca1-48e0eb13f29b",
#           "type": "string"
#         },
#         "links": {
#           "$ref": "GradeChangeEventLinks"
#         }
#       }
#     }
#
class GradeChangeAuditApiController < AuditorApiController
  include Api::V1::GradeChangeEvent

  # @API Query by assignment.
  #
  # List grade change events for a given assignment.
  #
  # @argument start_time [Optional, DateTime]
  #   The beginning of the time range from which you want events.
  #
  # @argument end_time [Optional, Datetime]
  #   The end of the time range from which you want events.
  #
  # @returns [GradeChangeEvent]
  #
  def for_assignment
    @assignment = Assignment.active.find(params[:assignment_id])
    unless @assignment.context.root_account == @domain_root_account
      raise ActiveRecord::RecordNotFound, "Couldn't find assignment with API id '#{params[:assignment_id]}'"
    end
    if authorize
      events = Auditors::GradeChange.for_assignment(@assignment, query_options)
      render_events(events, polymorphic_url([:api_v1, :audit_grade_change, @assignment]))
    else
      render_unauthorized_action
    end
  end

  # @API Query by course.
  #
  # List grade change events for a given course.
  #
  # @argument start_time [Optional, DateTime]
  #   The beginning of the time range from which you want events.
  #
  # @argument end_time [Optional, Datetime]
  #   The end of the time range from which you want events.
  #
  # @returns [GradeChangeEvent]
  #
  def for_course
    @course = @domain_root_account.all_courses.active.find(params[:course_id])
    if authorize
      events = Auditors::GradeChange.for_course(@course, query_options)
      render_events(events, polymorphic_url([:api_v1, :audit_grade_change, @course]))
    else
      render_unauthorized_action
    end
  end

  # @API Query by student.
  #
  # List grade change events for a given student.
  #
  # @argument start_time [Optional, DateTime]
  #   The beginning of the time range from which you want events.
  #
  # @argument end_time [Optional, Datetime]
  #   The end of the time range from which you want events.
  #
  # @returns [GradeChangeEvent]
  #
  def for_student
    @student = User.active.find(params[:student_id])
    unless @student.associated_accounts.to_a.include?(@domain_root_account)
      raise ActiveRecord::RecordNotFound, "Couldn't find user with API id '#{params[:student_id]}'"
    end
    if authorize
      events = Auditors::GradeChange.for_root_account_student(@domain_root_account, @student, query_options)
      render_events(events, api_v1_audit_grade_change_student_url(@student))
    else
      render_unauthorized_action
    end
  end

  # @API Query by grader.
  #
  # List grade change events for a given grader.
  #
  # @argument start_time [Optional, DateTime]
  #   The beginning of the time range from which you want events.
  #
  # @argument end_time [Optional, Datetime]
  #   The end of the time range from which you want events.
  #
  # @returns [GradeChangeEvent]
  #
  def for_grader
    @grader = User.active.find(params[:grader_id])
    unless @grader.associated_accounts.to_a.include?(@domain_root_account)
      raise ActiveRecord::RecordNotFound, "Couldn't find user with API id '#{params[:grader_id]}'"
    end
    if authorize
      events = Auditors::GradeChange.for_root_account_grader(@domain_root_account, @grader, query_options)
      render_events(events, api_v1_audit_grade_change_grader_url(@grader))
    else
      render_unauthorized_action
    end
  end

  private

  def authorize
    @domain_root_account.grants_right?(@current_user, session, :view_grade_changes)
  end

  def render_events(events, route)
    events = Api.paginate(events, self, route)
    render :json => grade_change_events_compound_json(events, @current_user, session)
  end
end
