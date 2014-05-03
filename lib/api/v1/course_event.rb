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

module Api::V1::CourseEvent
  include Api
  include Api::V1::Course
  include Api::V1::PageView
  include Api::V1::User

  def course_event_json(event, user, session)
    links = {
      :course => Shard.relative_id_for(event.course_id, Shard.current, Shard.current),
      :page_view => event.page_view.nil? ? nil : event.request_id,
      :user => Shard.relative_id_for(event.user_id, Shard.current, Shard.current)
    }

    {
      :id => event.id,
      :created_at => event.created_at.in_time_zone,
      :event_type => event.event_type,

      # since its storing data as json it would be nice just to
      # return it directly instead of having to parse it each time.
      :event_data => event.event_data,
      :links => links
    }
  end

  def course_events_json(events, user, session)
    events.map{ |event| course_event_json(event, user, session) }
  end

  def course_events_compound_json(events, user, session)
    {
      links: links_json(events, user, session),
      events: course_events_json(events, user, session),
      linked: linked_json(events, user, session)
    }
  end

  private

  def links_json(events, user, session)
    {
      "events.course" => templated_url(:api_v1_course_url, "{events.course}"),
      "events.user" => nil
    }
  end

  def linked_json(events, user, session)
    course_ids = events.map{ |event| event.course_id }
    courses = Course.find_all_by_id(course_ids) if course_ids.length > 0
    courses ||= []

    page_view_ids = events.map{ |event| event.request_id }
    page_views = PageView.find_all_by_id(page_view_ids) if page_view_ids.length > 0
    page_views ||= []

    user_ids = events.map{ |event| event.user_id }
    users = User.find_all_by_id(user_ids) if user_ids.length > 0
    users ||= []

    {
      page_views: page_views_json(page_views, user, session),
      courses: courses_json(courses, user, session, [], []),
      users: users_json(users, user, session, [], @domain_root_account)
    }
  end
end
