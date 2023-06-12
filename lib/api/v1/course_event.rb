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

module Api::V1::CourseEvent
  include Api
  include Api::V1::Course
  include Api::V1::PageView
  include Api::V1::User

  def course_event_json(event, _user, _session)
    links = {
      course: Shard.relative_id_for(event.course_id, Shard.current, Shard.current),
      page_view: event.request_id && PageView.find_by(id: event.request_id).try(:id),
      user: Shard.relative_id_for(event.user_id, Shard.current, Shard.current),
      sis_batch: Shard.relative_id_for(event.sis_batch_id, Shard.current, Shard.current)
    }

    # Since copied/reset events relate to another course lets put that where it
    # belongs according to jsonapi.
    event_data = event.event_data
    if event.event_type == "copied_to" || event.event_type == "copied_from" || event.event_type == "reset_to" || event.event_type == "reset_from"
      # try to convert the id to a relative id.
      if event_data.key?(event.event_type)
        event_data[event.event_type] = Shard.relative_id_for(event_data[event.event_type], Shard.current, Shard.current)
      end

      links = event_data.merge(links)
      event_data = {}
    end

    {
      id: event.uuid,
      created_at: event.created_at.in_time_zone,
      event_type: event.event_type,
      event_source: event.event_source,

      # since its storing data as json it would be nice just to
      # return it directly instead of having to parse it each time.
      event_data:,
      links:
    }
  end

  def course_events_json(events, user, session)
    events.map { |event| course_event_json(event, user, session) }
  end

  def course_events_compound_json(events, user, session)
    {
      links: links_json,
      events: course_events_json(events, user, session),
      linked: linked_json(events, user, session)
    }
  end

  private

  def links_json
    {
      "events.course" => templated_url(:api_v1_course_url, "{events.course}"),
      "events.user" => nil,
      "events.sis_batch" => nil
    }
  end

  def linked_json(events, user, session)
    course_ids = events.filter_map(&:course_id)
    course_ids.concat(events.filter_map do |event|
      event.event_data[event.event_type] if event.event_data
    end)
    courses = Course.where(id: course_ids).to_a unless course_ids.empty?
    courses ||= []

    page_view_ids = events.filter_map(&:request_id)
    page_views = PageView.find_all_by_id(page_view_ids) unless page_view_ids.empty?
    page_views ||= []

    user_ids = events.filter_map(&:user_id)
    users = User.where(id: user_ids).to_a unless user_ids.empty?
    users ||= []

    {
      page_views: page_views_json(page_views, user, session),
      courses: courses_json(courses, user, session, [], []),
      users: users_json(users, user, session, [], @domain_root_account)
    }
  end
end
