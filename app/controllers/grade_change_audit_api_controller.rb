# frozen_string_literal: true

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

  # @API Query by assignment
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

    @assignment = api_find(Assignment.active, params[:assignment_id])
    unless @assignment.context.root_account == @domain_root_account
      raise ActiveRecord::RecordNotFound, "Couldn't find assignment with API id '#{params[:assignment_id]}'"
    end

    events = Auditors::GradeChange.for_assignment(@assignment, query_options)
    render_events(events, polymorphic_url([:api_v1, :audit_grade_change, @assignment]))
  end

  # @API Query by course
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
    rescue ActiveRecord::RecordNotFound => e
      return render_unauthorized_action unless admin_authorized?

      raise e
    end

    return render_unauthorized_action unless course_authorized?(course)

    events = Auditors::GradeChange.for_course(course, query_options)
    render_events(events, polymorphic_url([:api_v1, :audit_grade_change, course]), course:)
  end

  # @API Query by student
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
    render_events(events, api_v1_audit_grade_change_student_url(@student), remove_anonymous: true)
  end

  # @API Query by grader
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

  # @API Advanced query
  #
  # List grade change events satisfying all given parameters. Teachers may query for events in courses they teach.
  # Queries without +course_id+ require account administrator rights.
  #
  # At least one of +course_id+, +assignment_id+, +student_id+, or +grader_id+ must be specified.
  #
  # @argument course_id [Optional, Integer]
  #   Restrict query to events in the specified course.
  #
  # @argument assignment_id [Optional, Integer]
  #   Restrict query to the given assignment. If "override" is given, query the course final grade override instead.
  #
  # @argument student_id [Optional, Integer]
  #   User id of a student to search grading events for.
  #
  # @argument grader_id [Optional, Integer]
  #   User id of a grader to search grading events for.
  #
  # @argument start_time [DateTime]
  #   The beginning of the time range from which you want events.
  #
  # @argument end_time [DateTime]
  #   The end of the time range from which you want events.
  #
  # @returns [GradeChangeEvent]
  #
  def query
    assignment = Auditors::GradeChange::COURSE_OVERRIDE_ASSIGNMENT if params[:assignment_id] == "override"

    if params[:course_id].present?
      course = api_find(Course, params[:course_id])
      return render_unauthorized_action unless course_authorized?(course)

      student = api_find(course.all_users, params[:student_id]) if params[:student_id].present?
      grader = api_find(User.active, params[:grader_id]) if params[:grader_id].present?
      assignment ||= api_find(course.assignments, params[:assignment_id]) if params[:assignment_id].present?
    else
      return render_unauthorized_action unless admin_authorized?

      student = api_find(User.active, params[:student_id]) if params[:student_id].present?
      grader = api_find(User.active, params[:grader_id]) if params[:grader_id].present?
      assignment ||= api_find(Assignment, params[:assignment_id]) if params[:assignment_id].present?
    end

    conditions = {}
    if course
      conditions[:context_id] = course.id
      conditions[:context_type] = "Course"
    end
    conditions[:student_id] = student.id if student
    conditions[:grader_id] = grader.id if grader
    conditions[:assignment_id] = assignment.id if assignment
    if conditions.empty?
      return render json: { message: "Must specify at least one query condition" }, status: :bad_request
    end

    events = Auditors::GradeChange.for_scope_conditions(conditions, query_options)
    render_events(events, api_v1_audit_grade_change_url, course:, remove_anonymous: params[:student_id].present?)
  end

  # TODO: remove Cassandra cruft and make Gradebook History use the admin search above
  # once OSS users have been given the opportunity to migrate to Postgres auditors
  def for_course_and_other_parameters
    begin
      course = Course.find(params[:course_id])
    rescue ActiveRecord::RecordNotFound => e
      return render_unauthorized_action unless admin_authorized?

      raise e
    end

    return render_unauthorized_action unless course_authorized?(course)

    args = { course: }
    restrict_to_override_grades = params[:assignment_id] == "override"
    if restrict_to_override_grades
      args[:assignment] = Auditors::GradeChange::COURSE_OVERRIDE_ASSIGNMENT
    elsif params[:assignment_id]
      args[:assignment] = api_find(course.assignments, params[:assignment_id])
    end
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

    route_args = restrict_to_override_grades ? args.merge({ assignment: "override" }) : args
    render_events(events, send(url_method, route_args), course:, remove_anonymous: params[:student_id].present?)
  end

  private

  def admin_authorized?
    @domain_root_account.grants_right?(@current_user, session, :view_grade_changes)
  end

  def course_authorized?(course)
    course.grants_any_right?(@current_user, session, :manage_grades, :view_all_grades)
  end

  def render_events(events, route, course: nil, remove_anonymous: false)
    events = BookmarkedCollection.filter(events) { |event| !event.override_grade? } unless include_override_grades?(course:)
    events = Api.paginate(events, self, route)

    if params.fetch(:include, []).include?("current_grade")
      grades = current_grades(events)
      events.each { |event| event.grade_current = current_grade_for_event(event, grades) }

      apply_current_override_grades!(events)
    end

    if course.present?
      events = events_visible_to_current_user(course, events)
    end

    # In the case of for_student, simply anonymizing the data would continue
    # to leak information, so just drop the event completely while the
    # assignment is still anonymous and muted.
    events = remove_anonymous ? remove_anonymous_events(events) : anonymize_events(events)
    render json: grade_change_events_compound_json(events, @current_user, session)
  end

  def remove_anonymous_events(events)
    assignments_anonymous_and_muted = anonymous_and_muted(events)

    events.reject do |event|
      assignment_id = Shard.global_id_for(event["attributes"].fetch("assignment_id"))
      assignments_anonymous_and_muted[assignment_id]
    end
  end

  def anonymize_events(events)
    assignments_anonymous_and_muted = anonymous_and_muted(events)

    events.each do |event|
      attributes = event["attributes"]
      assignment_id = Shard.global_id_for(attributes.fetch("assignment_id"))
      attributes["student_id"] = nil if assignments_anonymous_and_muted[assignment_id]
    end
  end

  def anonymous_and_muted(events)
    assignment_ids = events.filter_map { |event| event["attributes"].fetch("assignment_id") }
    assignments = api_find_all(Assignment, assignment_ids)
    assignments_anonymous_and_muted = {}

    assignments.each do |assignment|
      assignments_anonymous_and_muted[assignment.global_id] = assignment.anonymous_grading? && assignment.muted?
    end

    assignments_anonymous_and_muted
  end

  def events_visible_to_current_user(course, events)
    visible_student_ids =
      course.students_visible_to(@current_user, include: :priors_and_deleted).index_by(&:global_id)

    events.select { |event| visible_student_ids[Shard.global_id_for(event.student_id)] }
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

  def apply_current_override_grades!(events)
    override_events = events.select(&:override_grade?)
    return if override_events.blank?

    current_scores = current_override_scores_query(override_events).each_with_object({}) do |score, hash|
      key = key_from_ids(score.enrollment.course_id, score.enrollment.user_id, score.grading_period_id)
      hash[key] = score
    end

    override_events.each do |event|
      grading_period_id = event.in_grading_period? ? event.grading_period_id : nil
      key = key_from_ids(event.context_id, event.student_id, grading_period_id)

      current_score = current_scores[key]
      event.grade_current = if current_score&.override_grade
                              current_score.override_grade
                            elsif current_score&.override_score
                              I18n.n(current_score.override_score, percentage: true)
                            end
    end
  end

  def current_override_scores_query(events)
    base_score_scope = Score.active.joins(:enrollment).preload(:enrollment)
    scopes = []

    events_with_grading_period = events.select(&:in_grading_period?)
    if events_with_grading_period.present?
      values = events_with_grading_period.map do |event|
        key = key_from_ids(event.context_id, event.student_id, event.grading_period_id).join(",")
        "(#{key})"
      end.join(", ")

      scopes << base_score_scope
                .where("(enrollments.course_id, enrollments.user_id, scores.grading_period_id) IN (#{values})")
    end

    events_without_grading_period = events.reject(&:in_grading_period?)
    if events_without_grading_period.present?
      values = events_without_grading_period.map do |event|
        key = key_from_ids(event.context_id, event.student_id).join(",")
        "(#{key})"
      end.join(", ")

      scopes << base_score_scope
                .where(course_score: true)
                .where("(enrollments.course_id, enrollments.user_id) IN (#{values})")
    end

    scopes.reduce { |result, scope| result.union(scope) }
  end

  def key_from_ids(*ids)
    # If we fetched our override change records from Postgres, the relevant ID
    # fields will already be relative to the current shard and so the below
    # method won't change them. If we got them from Cassandra, however, we have
    # to adjust them before searching.

    ids.map { |id| Shard.relative_id_for(id, Shard.current, Shard.current) }
  end

  def include_override_grades?(course: nil)
    course.blank? || course.allow_final_grade_override?
  end
end
