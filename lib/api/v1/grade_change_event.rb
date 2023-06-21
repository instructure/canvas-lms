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

module Api::V1::GradeChangeEvent
  include Api
  include Api::V1::User
  include Api::V1::Course
  include Api::V1::Assignment
  include Api::V1::Submission
  include Api::V1::PageView

  def grade_change_event_json(event, _user, _session)
    links = {
      course: Shard.relative_id_for(event.course_id, Shard.current, Shard.current),
      student: Shard.relative_id_for(event.student_id, Shard.current, Shard.current)&.to_s,
      grader: Shard.relative_id_for(event.grader_id, Shard.current, Shard.current)&.to_s,
      page_view: event.request_id && PageView.find_by(id: event.request_id).try(:id)
    }
    links[:assignment] = Shard.relative_id_for(event.assignment_id, Shard.current, Shard.current) unless event.override_grade?

    json = {
      id: event.uuid,
      created_at: event.created_at.in_time_zone,
      event_type: event.event_type,
      grade_before: display_grade(event:, grade: event.grade_before, score: event.score_before),
      grade_after: display_grade(event:, grade: event.grade_after, score: event.score_after),
      excused_before: event.excused_before,
      excused_after: event.excused_after,
      graded_anonymously: event.graded_anonymously,
      points_possible_after: event.points_possible_after,
      points_possible_before: event.points_possible_before,
      version_number: event.version_number,
      links:
    }

    json[:grade_current] = event.grade_current if event.grade_current.present?
    json[:course_override_grade] = true if event.override_grade?
    json
  end

  def grade_change_events_json(events, user, session)
    events.map { |event| grade_change_event_json(event, user, session) }
  end

  def grade_change_events_compound_json(events, user, session)
    {
      links: links_json,
      events: grade_change_events_json(events, user, session),
      linked: linked_json(events, user, session)
    }
  end

  private

  def links_json
    # This should include users and page_views.  There is no end point
    # for returning single json objects for those models.
    user = { href: nil, type: "user" }
    {
      "events.assignment" => templated_url(:api_v1_course_assignment_url, "{events.course}", "{events.assignment}"),
      "events.course" => templated_url(:api_v1_course_url, "{events.course}"),
      "events.student" => user,
      "events.grader" => user,
      "events.page_view" => nil
    }
  end

  def linked_json(events, user, session)
    course_ids = events.filter_map(&:course_id)
    courses = Course.where(id: course_ids).to_a unless course_ids.empty?
    courses ||= []

    assignment_ids = events.filter_map(&:assignment_id)
    assignments = Assignment.where(id: assignment_ids).to_a unless assignment_ids.empty?
    assignments ||= []

    user_ids = events.filter_map(&:grader_id)
    user_ids.concat(events.filter_map(&:student_id))
    users = User.where(id: user_ids).to_a unless user_ids.empty?
    users ||= []

    page_view_ids = events.filter_map(&:request_id)
    page_views = PageView.find_all_by_id(page_view_ids) unless page_view_ids.empty?
    page_views ||= []

    {
      page_views: page_views_json(page_views, user, session),
      assignments: assignments_json(assignments, user, session),
      courses: courses_json(courses, user, session, [], []),
      users: users_json(users, user, session, [], @domain_root_account)
    }
  end

  def display_grade(event:, grade:, score:)
    # Unlike for individual assignments, override grades get saved with blank
    # grade_before/grade_after values if the course has no grading scheme.  If
    # we have a score but no grade, fall back to showing the score.
    return grade unless event.override_grade? && grade.blank?

    score.present? ? I18n.n(score, percentage: true) : nil
  end
end
