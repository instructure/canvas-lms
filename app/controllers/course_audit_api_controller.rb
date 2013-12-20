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

# @API Course Audit log
#
# Query audit log of course events.
#
# Only available if the server has configured audit logs; will return 404 Not
# Found response otherwise.
#
# For each endpoint, a compound document is returned. The primary collection of
# event objects is paginated, ordered by date descending. Secondary collections
# of courses, users and page_views related to the returned events
# are also included.
#
# @object CourseEvent
#     {
#       // ID of the event.
#       "id": "e2b76430-27a5-0131-3ca1-48e0eb13f29b",
#
#       // timestamp of the event
#       "created_at": "2012-07-19T15:00:00-06:00",
#
#       // Course event type
#       // The event type defines the type and schema of the event_data object.
#       "event_type": "updated",
#
#       // Course event data
#       // Depeding on the event type.  This will return an object
#       // containing the relevant event data.  An updated event
#       // type will return an UpdatedEventData object.
#       "event_data": {
#       },
#
#       // Jsonapi.org links
#       "links": {
#          // ID of the course for the event.
#          "course": "12345",
#
#          // ID of the user for the event (who made the change).
#          "user": "12345",
#
#          // ID of the page view during the event if it exists.
#          "page_view": "e2b76430-27a5-0131-3ca1-48e0eb13f29b"
#       }
#     }
#
# The created event data object returns all the fields that were set in the
# format of the following example.  If a field does not exist it was not set.
# The value of each field changed is in the format of [:old_value, :new_value].
#
# @object CreatedEventData
#   {
#     "name": [ null, "Course 1" ],
#     "start_at": [ null, "2012-01-19T15:00:00-06:00" ],
#     "conclude_at": [ null, "2012-01-19T15:00:00-08:00" ],
#     "is_public": [ null, false ]
#   }
#
# The updated event data object returns all the fields that have
# changed in the format of the following example.  If a field does
# not exist it was not changed.  The value is an array that contains
# the before and after values for the change as in [:old_value, :new_value].
#
# @object UpdatedEventData
#   {
#     "name": [ "Course 1", "Course 2" ],
#     "start_at": [ "2012-01-19T15:00:00-06:00", "2012-07-19T15:00:00-06:00" ],
#     "conclude_at": [ "2012-01-19T15:00:00-08:00", "2012-07-19T15:00:00-08:00" ],
#     "is_public": [ true, false ]
#   }
#
# The concluded event data object returns an empty object.  The concluded event
# does not have any log data associated.
#
# @object ConcludedEventData
#   {
#   }
#
class CourseAuditApiController < AuditorApiController
  include Api::V1::CourseEvent

  # @API Query by course.
  #
  # List course change events for a given course.
  #
  # @argument start_time [Optional, DateTime]
  #   The beginning of the time range from which you want events.
  #
  # @argument end_time [Optional, Datetime]
  #   The end of the time range from which you want events.
  #
  # @returns [CourseEvent]
  #
  def for_course
    @course = Course.active.find(params[:course_id])
    if authorize
      events = Auditors::Course.for_course(@course, query_options)
      render_events(events, api_v1_audit_course_for_course_url(@course))
    else
      render_unauthorized_action
    end
  end

  private

  def authorize
    @domain_root_account.grants_right?(@current_user, session, :view_course_changes)
  end

  def render_events(events, route)
    events = Api.paginate(events, self, route)
    render :json => course_events_compound_json(events, @current_user, session)
  end
end
