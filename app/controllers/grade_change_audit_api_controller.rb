#
# Copyright (C) 2013 - present Instructure, Inc.
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
#         "excused_after": {
#           "description": "Boolean indicating whether the submission was excused after the change.",
#           "example": true,
#           "type": "boolean"
#         },
#         "excused_before": {
#           "description": "Boolean indicating whether the submission was excused before the change.",
#           "example": false,
#           "type": "boolean"
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
#         "graded_anonymously": {
#           "description": "Boolean indicating whether the student name was visible when the grade was given. Could be null if the grade change record was created before this feature existed.",
#           "example": true,
#           "type": "boolean"
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
  # @argument start_time [DateTime]
  #   The beginning of the time range from which you want events.
  #
  # @argument end_time [DateTime]
  #   The end of the time range from which you want events.
  #
  # @returns [GradeChangeEvent]
  #
  def for_assignment
    return render_unauthorized_action unless admin_authorized?

    @assignment = Assignment.active.find(params[:assignment_id])
    unless @assignment.context.root_account == @domain_root_account
      raise ActiveRecord::RecordNotFound, "Couldn't find assignment with API id '#{params[:assignment_id]}'"
    end

    events = Auditors::GradeChange.for_assignment(@assignment, query_options)
    render_events(events, polymorphic_url([:api_v1, :audit_grade_change, @assignment]))
  end

  # @API Query by course.
  #
  # List grade change events for a given course.
  #
  # @argument start_time [DateTime]
  #   The beginning of the time range from which you want events.
  #
  # @argument end_time [DateTime]
  #   The end of the time range from which you want events.
  #
  # @returns [GradeChangeEvent]
  #
  def for_course
    begin
      course = Course.find(params[:course_id])
    rescue ActiveRecord::RecordNotFound => not_found
      return render_unauthorized_action unless admin_authorized?
      raise not_found
    end

    return render_unauthorized_action unless course_authorized?(course)

    events = Auditors::GradeChange.for_course(course, query_options)
    render_events(events, polymorphic_url([:api_v1, :audit_grade_change, course]), course: course)
  end

  # @API Query by student.
  #
  # List grade change events for a given student.
  #
  # @argument start_time [DateTime]
  #   The beginning of the time range from which you want events.
  #
  # @argument end_time [DateTime]
  #   The end of the time range from which you want events.
  #
  # @returns [GradeChangeEvent]
  #
  def for_student
    return render_unauthorized_action unless admin_authorized?

    @student = User.active.find(params[:student_id])
    unless @domain_root_account.associated_user?(@student)
      raise ActiveRecord::RecordNotFound, "Couldn't find user with API id '#{params[:student_id]}'"
    end

    events = Auditors::GradeChange.for_root_account_student(@domain_root_account, @student, query_options)
    render_events(events, api_v1_audit_grade_change_student_url(@student))
  end

  # @API Query by grader.
  #
  # List grade change events for a given grader.
  #
  # @argument start_time [DateTime]
  #   The beginning of the time range from which you want events.
  #
  # @argument end_time [DateTime]
  #   The end of the time range from which you want events.
  #
  # @returns [GradeChangeEvent]
  #
  def for_grader
    return render_unauthorized_action unless admin_authorized?

    @grader = User.active.find(params[:grader_id])
    unless @domain_root_account.associated_user?(@grader)
      raise ActiveRecord::RecordNotFound, "Couldn't find user with API id '#{params[:grader_id]}'"
    end

    events = Auditors::GradeChange.for_root_account_grader(@domain_root_account, @grader, query_options)
    render_events(events, api_v1_audit_grade_change_grader_url(@grader))
  end

  def for_course_and_other_parameters
    begin
      course = Course.find(params[:course_id])
    rescue ActiveRecord::RecordNotFound => not_found
      return render_unauthorized_action unless admin_authorized?
      raise not_found
    end

    return render_unauthorized_action unless course_authorized?(course)

    args = { course: course }
    args[:assignment] = course.assignments.find(params[:assignment_id]) if params[:assignment_id]
    args[:grader] = course.all_users.find(params[:grader_id]) if params[:grader_id]
    args[:student] = course.all_users.find(params[:student_id]) if params[:student_id]

    url_method = if args[:assignment] && args[:grader] && args[:student]
      :api_v1_audit_grade_change_course_assignment_grader_student_url
    elsif args[:assignment] && args[:grader]
      :api_v1_audit_grade_change_course_assignment_grader_url
    elsif args[:assignment] && args[:student]
      :api_v1_audit_grade_change_course_assignment_student_url
    elsif args[:assignment]
      :api_v1_audit_grade_change_course_assignment_url
    elsif args[:grader] && args[:student]
      :api_v1_audit_grade_change_course_grader_student_url
    elsif args[:grader]
      :api_v1_audit_grade_change_course_grader_url
    elsif args[:student]
      :api_v1_audit_grade_change_course_student_url
    end

    events = Auditors::GradeChange.for_course_and_other_arguments(course, args, query_options)
    render_events(events, send(url_method, args), course: course)
  end

  private

  def admin_authorized?
    @domain_root_account.grants_right?(@current_user, session, :view_grade_changes)
  end

  def course_authorized?(course)
    course.grants_any_right?(@current_user, session, :manage_grades, :view_all_grades)
  end

  def render_events(events, route, course: nil)
    events = Api.paginate(events, self, route)

    if params.fetch(:include, []).include?("current_grade")
      grades = current_grades(events)
      events.each { |event| event.grade_current = current_grade_for_event(event, grades) }
    end

    if course.present?
      events = events_visible_to_current_user(course, events)
    end

    render :json => grade_change_events_compound_json(events, @current_user, session)
  end

  def events_visible_to_current_user(course, events)
    visible_student_ids =
      course.students_visible_to(@current_user, include: :priors_and_deleted).index_by(&:global_id)

    events.select { |event| visible_student_ids[event.student_id] }
  end

  def current_grade_for_event(event, grades)
    submission_id = Shard.relative_id_for(event.submission_id, Shard.current, Shard.current)
    grades.fetch(submission_id, I18n.t("N/A"))
  end

  def current_grades(events)
    submission_ids = events.map(&:submission_id)
    grades = Submission.where(id: submission_ids).pluck(:id, :grade)
    grades.each_with_object({}) { |(key, value), hsh| hsh[key] = value }
  end
end
