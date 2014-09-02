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

module Api::V1::GradeChangeEvent
  include Api
  include Api::V1::User
  include Api::V1::Course
  include Api::V1::Assignment
  include Api::V1::Submission
  include Api::V1::PageView

  def grade_change_event_json(event, user, session)
    links = {
      :assignment => Shard.relative_id_for(event.assignment_id, Shard.current, Shard.current),
      :course => Shard.relative_id_for(event.course_id, Shard.current, Shard.current),
      :student => Shard.relative_id_for(event.student_id, Shard.current, Shard.current),
      :grader => Shard.relative_id_for(event.grader_id, Shard.current, Shard.current),
      :page_view => event.request_id && PageView.find_by_id(event.request_id).try(:id)
    }

    {
      :id => event.id,
      :created_at => event.created_at.in_time_zone,
      :event_type => event.event_type,
      :grade_before => event.grade_before,
      :grade_after => event.grade_after,
      :version_number => event.version_number,
      :links => links
    }
  end

  def grade_change_events_json(events, user, session)
    events.map{ |event| grade_change_event_json(event, user, session) }
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
    user = { href: nil, type: 'user' }
    {
      "events.assignment" => templated_url(:api_v1_course_assignment_url, "{events.course}", "{events.assignment}"),
      "events.course" => templated_url(:api_v1_course_url, "{events.course}"),
      "events.student" => user,
      "events.grader" => user,
      "events.page_view" => nil
    }
  end

  def linked_json(events, user, session)
    course_ids = events.map{ |event| event.course_id }.compact
    courses = Course.find_all_by_id(course_ids) if course_ids.length > 0
    courses ||= []

    assignment_ids = events.map{ |event| event.assignment_id }.compact
    assignments = Assignment.find_all_by_id(assignment_ids) if assignment_ids.length > 0
    assignments ||= []

    user_ids = events.map{ |event| event.grader_id }.compact
    user_ids.concat(events.map{ |event| event.student_id }.compact)
    users = User.find_all_by_id(user_ids) if user_ids.length > 0
    users ||= []

    page_view_ids = events.map{ |event| event.request_id }.compact
    page_views = PageView.find_all_by_id(page_view_ids) if page_view_ids.length > 0
    page_views ||= []

    {
      page_views: page_views_json(page_views, user, session),
      assignments: assignments_json(assignments, user, session),
      courses: courses_json(courses, user, session, [], []),
      users: users_json(users, user, session, [], @domain_root_account)
    }
  end
end
