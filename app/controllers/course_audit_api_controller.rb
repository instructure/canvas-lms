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
# The event data for `ConcludedEventData`, `UnconcludedEventData`, `PublishedEventData`,
# `UnpublishedEventData`, `DeletedEventData`, `RestoredEventData`, `CopiedFromEventData`,
# and `CopiedToEventData` objects will return a empty objects as these do not have
# any additional log data associated.
#
# @model CourseEventLink
#     {
#       "id": "CourseEventLink",
#       "description": "",
#       "properties": {
#         "course": {
#           "description": "ID of the course for the event.",
#           "example": 12345,
#           "type": "integer"
#         },
#         "user": {
#           "description": "ID of the user for the event (who made the change).",
#           "example": 12345,
#           "type": "integer"
#         },
#         "page_view": {
#           "description": "ID of the page view during the event if it exists.",
#           "example": "e2b76430-27a5-0131-3ca1-48e0eb13f29b",
#           "type": "string"
#         },
#         "copied_from": {
#           "description": "ID of the course that this course was copied from. This is only included if the event_type is copied_from.",
#           "example": 12345,
#           "type": "integer"
#         },
#         "copied_to": {
#           "description": "ID of the course that this course was copied to. This is only included if the event_type is copied_to.",
#           "example": 12345,
#           "type": "integer"
#         },
#         "sis_batch": {
#           "description": "ID of the SIS batch that triggered the event.",
#           "example": 12345,
#           "type": "integer"
#         }
#       }
#     }
#
# @model CourseEvent
#     {
#       "id": "CourseEvent",
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
#           "description": "Course event type The event type defines the type and schema of the event_data object.",
#           "example": "updated",
#           "type": "string"
#         },
#         "event_data": {
#           "description": "Course event data depending on the event type.  This will return an object containing the relevant event data.  An updated event type will return an UpdatedEventData object.",
#           "example": "{}",
#           "type": "string"
#         },
#         "event_source": {
#           "description": "Course event source depending on the event type.  This will return a string containing the source of the event.",
#           "example": "manual|sis|api",
#           "type": "string"
#         },
#         "links": {
#           "description": "Jsonapi.org links",
#           "example": "{\"course\"=>\"12345\", \"user\"=>\"12345\", \"page_view\"=>\"e2b76430-27a5-0131-3ca1-48e0eb13f29b\"}",
#           "$ref": "CourseEventLink"
#         }
#       }
#     }
#
# @model CreatedEventData
#     {
#       "id": "CreatedEventData",
#       "description": "The created event data object returns all the fields that were set in the format of the following example.  If a field does not exist it was not set. The value of each field changed is in the format of [:old_value, :new_value].  The created event type also includes a created_source field to specify what triggered the creation of the course.",
#       "properties": {
#         "name": {
#           "example": "[nil, \"Course 1\"]",
#           "type": "array",
#           "items": { "type": "string" }
#         },
#         "start_at": {
#           "example": "[nil, \"2012-01-19T15:00:00-06:00\"]",
#           "type": "array",
#           "items": { "type": "datetime" }
#         },
#         "conclude_at": {
#           "example": "[nil, \"2012-01-19T15:00:00-08:00\"]",
#           "type": "array",
#           "items": { "type": "datetime" }
#         },
#         "is_public": {
#           "example": "[nil, false]",
#           "type": "array",
#           "items": { "type": "boolean" }
#         },
#         "created_source": "manual|sis|api"
#       }
#     }
#
# @model UpdatedEventData
#     {
#       "id": "UpdatedEventData",
#       "description": "The updated event data object returns all the fields that have changed in the format of the following example.  If a field does not exist it was not changed.  The value is an array that contains the before and after values for the change as in [:old_value, :new_value].",
#       "properties": {
#         "name": {
#           "example": "[\"Course 1\", \"Course 2\"]",
#           "type": "array",
#           "items": { "type": "string" }
#         },
#         "start_at": {
#           "example": "[\"2012-01-19T15:00:00-06:00\", \"2012-07-19T15:00:00-06:00\"]",
#           "type": "array",
#           "items": { "type": "datetime" }
#         },
#         "conclude_at": {
#           "example": "[\"2012-01-19T15:00:00-08:00\", \"2012-07-19T15:00:00-08:00\"]",
#           "type": "array",
#           "items": { "type": "datetime" }
#         },
#         "is_public": {
#           "example": "[true, false]",
#           "type": "array",
#           "items": { "type": "boolean" }
#         }
#       }
#     }
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
    @course = Course.find(params[:course_id])
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
