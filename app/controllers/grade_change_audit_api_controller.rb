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
# For each endpoint, a compound document is returned. The primary collection of
# event objects is paginated, ordered by date descending. Secondary collections
# of assignments, courses, students and graders related to the returned events
# are also included. Refer to the Assignment, Courses, and Users APIs for
# descriptions of the objects in those collections.
#
# @object GradeChangeEvent
#     {
#       // ID of the event.
#       "id": "e2b76430-27a5-0131-3ca1-48e0eb13f29b",
#
#       // timestamp of the event
#       "created_at": "2012-07-19T15:00:00-06:00",
#
#       // GradeChange event type
#       "event_type": "grade_change",
#
#       // The grade after the change.
#       "grade_after": "8",
#
#       // The grade before the change.
#       "grade_before": "8",
#
#       // Version Number of the grade change submission.
#       "version_number": "1",
#
#       "links": {
#          // ID of the assignment associated with the event.
#          "assignment": 2319,
#
#          // ID of the course associated with the event. will match the
#          // context_id in the associated assignment if the context type
#          // for the assignment is a course.
#          "course": 2319,
#
#          // ID of the student associated with the event. will match the
#          // user_id in the associated submission.
#          "student": 2319,
#
#          // ID of the grader associated with the event. will match the
#          // grader_id in the associated submission.
#          "grader": 2319,
#
#          // ID of the page view during the event if it exists.
#          "page_view": "e2b76430-27a5-0131-3ca1-48e0eb13f29b"
#       }
#     }
#
class GradeChangeAuditApiController < ApplicationController
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
    @course = Course.active.find(params[:course_id])
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

  def query_options(account=nil)
    start_time = TimeHelper.try_parse(params[:start_time])
    end_time = TimeHelper.try_parse(params[:end_time])

    options = {}
    options[:oldest] = start_time if start_time
    options[:newest] = end_time if end_time
    options
  end
end
