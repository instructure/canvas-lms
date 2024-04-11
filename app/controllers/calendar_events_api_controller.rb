# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

require "rrule"

# @API Calendar Events
#
# API for creating, accessing and updating calendar events.
#
# @model CalendarEvent
#     {
#       "id": "CalendarEvent",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "The ID of the calendar event",
#           "example": 234,
#           "type": "integer"
#         },
#         "title": {
#           "description": "The title of the calendar event",
#           "example": "Paintball Fight!",
#           "type": "string"
#         },
#         "start_at": {
#           "description": "The start timestamp of the event",
#           "example": "2012-07-19T15:00:00-06:00",
#           "type": "datetime"
#         },
#         "end_at": {
#           "description": "The end timestamp of the event",
#           "example": "2012-07-19T16:00:00-06:00",
#           "type": "datetime"
#         },
#         "description": {
#           "description": "The HTML description of the event",
#           "example": "<b>It's that time again!</b>",
#           "type": "string"
#         },
#         "location_name": {
#           "description": "The location name of the event",
#           "example": "Greendale Community College",
#           "type": "string"
#         },
#         "location_address": {
#           "description": "The address where the event is taking place",
#           "example": "Greendale, Colorado",
#           "type": "string"
#         },
#         "context_code": {
#           "description": "the context code of the calendar this event belongs to (course, group, user, or account)",
#           "example": "course_123",
#           "type": "string"
#         },
#         "effective_context_code": {
#           "description": "if specified, it indicates which calendar this event should be displayed on. for example, a section-level event would have the course's context code here, while the section's context code would be returned above)",
#           "type": "string"
#         },
#         "context_name": {
#           "description": "the context name of the calendar this event belongs to (course, user or group)",
#           "example": "Chemistry 101",
#           "type": "string"
#         },
#         "all_context_codes": {
#           "description": "a comma-separated list of all calendar contexts this event is part of",
#           "example": "course_123,course_456",
#           "type": "string"
#         },
#         "workflow_state": {
#           "description": "Current state of the event ('active', 'locked' or 'deleted') 'locked' indicates that start_at/end_at cannot be changed (though the event could be deleted). Normally only reservations or time slots with reservations are locked (see the Appointment Groups API)",
#           "example": "active",
#           "type": "string"
#         },
#         "hidden": {
#           "description": "Whether this event should be displayed on the calendar. Only true for course-level events with section-level child events.",
#           "example": false,
#           "type": "boolean"
#         },
#         "parent_event_id": {
#           "description": "Normally null. If this is a reservation (see the Appointment Groups API), the id will indicate the time slot it is for. If this is a section-level event, this will be the course-level parent event.",
#           "type": "integer"
#         },
#         "child_events_count": {
#           "description": "The number of child_events. See child_events (and parent_event_id)",
#           "example": 0,
#           "type": "integer"
#         },
#         "child_events": {
#           "description": "Included by default, but may be excluded (see include[] option). If this is a time slot (see the Appointment Groups API) this will be a list of any reservations. If this is a course-level event, this will be a list of section-level events (if any)",
#           "type": "array",
#           "items": {"type": "integer"}
#         },
#         "url": {
#           "description": "URL for this calendar event (to update, delete, etc.)",
#           "example": "https://example.com/api/v1/calendar_events/234",
#           "type": "string"
#         },
#         "html_url": {
#           "description": "URL for a user to view this event",
#           "example": "https://example.com/calendar?event_id=234&include_contexts=course_123",
#           "type": "string"
#         },
#         "all_day_date": {
#           "description": "The date of this event",
#           "example": "2012-07-19",
#           "type": "datetime"
#         },
#         "all_day": {
#           "description": "Boolean indicating whether this is an all-day event (midnight to midnight)",
#           "example": false,
#           "type": "boolean"
#         },
#         "created_at": {
#           "description": "When the calendar event was created",
#           "example": "2012-07-12T10:55:20-06:00",
#           "type": "datetime"
#         },
#         "updated_at": {
#           "description": "When the calendar event was last updated",
#           "example": "2012-07-12T10:55:20-06:00",
#           "type": "datetime"
#         },
#         "appointment_group_id": {
#           "description": "Various Appointment-Group-related fields.These fields are only pertinent to time slots (appointments) and reservations of those time slots. See the Appointment Groups API. The id of the appointment group",
#           "type": "integer"
#         },
#         "appointment_group_url": {
#           "description": "The API URL of the appointment group",
#           "type": "string"
#         },
#         "own_reservation": {
#           "description": "If the event is a reservation, this a boolean indicating whether it is the current user's reservation, or someone else's",
#           "example": false,
#           "type": "boolean"
#         },
#         "reserve_url": {
#           "description": "If the event is a time slot, the API URL for reserving it",
#           "type": "string"
#         },
#         "reserved": {
#           "description": "If the event is a time slot, a boolean indicating whether the user has already made a reservation for it",
#           "example": false,
#           "type": "boolean"
#         },
#         "participant_type": {
#           "description": "The type of participant to sign up for a slot: 'User' or 'Group'",
#           "example": "User",
#           "type": "string"
#         },
#         "participants_per_appointment": {
#           "description": "If the event is a time slot, this is the participant limit",
#           "type": "integer"
#         },
#         "available_slots": {
#           "description": "If the event is a time slot and it has a participant limit, an integer indicating how many slots are available",
#           "type": "integer"
#         },
#         "user": {
#           "description": "If the event is a user-level reservation, this will contain the user participant JSON (refer to the Users API).",
#           "type": "string"
#         },
#         "group": {
#           "description": "If the event is a group-level reservation, this will contain the group participant JSON (refer to the Groups API).",
#           "type": "string"
#         },
#         "important_dates": {
#           "description": "Boolean indicating whether this has important dates.",
#           "example": true,
#           "type": "boolean"
#         },
#         "series_uuid": {
#           "description": "Identifies the recurring event series this event may belong to.",
#           "type": "uuid"
#         },
#         "rrule": {
#           "description": "An iCalendar RRULE for defining how events in a recurring event series repeat.",
#           "type": "string"
#         },
#         "series_head": {
#            "description": "Boolean indicating if is the first event in the series of recurring events.",
#            "type": "boolean"
#         },
#         "series_natural_language": {
#            "description": "A natural language expression of how events occur in the series.",
#            "type": "string",
#            "example": "Daily 5 times"
#         },
#         "blackout_date": {
#           "description": "Boolean indicating whether this has blackout date.",
#           "example": true,
#           "type": "boolean"
#         }
#       }
#     }
#
# @model AssignmentEvent
#     {
#       "id": "AssignmentEvent",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "A synthetic ID for the assignment",
#           "example": "assignment_987",
#           "type": "string"
#         },
#         "title": {
#           "description": "The title of the assignment",
#           "example": "Essay",
#           "type": "string"
#         },
#         "start_at": {
#           "description": "The due_at timestamp of the assignment",
#           "example": "2012-07-19T23:59:00-06:00",
#           "type": "datetime"
#         },
#         "end_at": {
#           "description": "The due_at timestamp of the assignment",
#           "example": "2012-07-19T23:59:00-06:00",
#           "type": "datetime"
#         },
#         "description": {
#           "description": "The HTML description of the assignment",
#           "example": "<b>Write an essay. Whatever you want.</b>",
#           "type": "string"
#         },
#         "context_code": {
#           "description": "the context code of the (course) calendar this assignment belongs to",
#           "example": "course_123",
#           "type": "string"
#         },
#         "workflow_state": {
#           "description": "Current state of the assignment ('published' or 'deleted')",
#           "example": "published",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "published",
#               "deleted"
#             ]
#           }
#         },
#         "url": {
#           "description": "URL for this assignment (note that updating/deleting should be done via the Assignments API)",
#           "example": "https://example.com/api/v1/calendar_events/assignment_987",
#           "type": "string"
#         },
#         "html_url": {
#           "description": "URL for a user to view this assignment",
#           "example": "http://example.com/courses/123/assignments/987",
#           "type": "string"
#         },
#         "all_day_date": {
#           "description": "The due date of this assignment",
#           "example": "2012-07-19",
#           "type": "datetime"
#         },
#         "all_day": {
#           "description": "Boolean indicating whether this is an all-day event (e.g. assignment due at midnight)",
#           "example": true,
#           "type": "boolean"
#         },
#         "created_at": {
#           "description": "When the assignment was created",
#           "example": "2012-07-12T10:55:20-06:00",
#           "type": "datetime"
#         },
#         "updated_at": {
#           "description": "When the assignment was last updated",
#           "example": "2012-07-12T10:55:20-06:00",
#           "type": "datetime"
#         },
#         "assignment": {
#           "description": "The full assignment JSON data (See the Assignments API)",
#           "$ref": "Assignment"
#         },
#         "assignment_overrides": {
#           "description": "The list of AssignmentOverrides that apply to this event (See the Assignments API). This information is useful for determining which students or sections this assignment-due event applies to.",
#           "$ref": "AssignmentOverride"
#         },
#         "important_dates": {
#           "description": "Boolean indicating whether this has important dates.",
#           "example": true,
#           "type": "boolean"
#         },
#         "rrule": {
#           "description": "An iCalendar RRULE for defining how events in a recurring event series repeat.",
#           "type": "string",
#           "example": "FREQ=DAILY;INTERVAL=1;COUNT=5"
#         },
#         "series_head": {
#            "description": "Trueif this is the first event in the series of recurring events.",
#            "type": "boolean"
#         },
#         "series_natural_language": {
#            "description": "A natural language expression of how events occur in the series.",
#            "type": "string",
#            "example": "Daily 5 times"
#         }
#       }
#     }
#
class CalendarEventsApiController < ApplicationController
  include Api::V1::CalendarEvent
  include CalendarConferencesHelper
  include ::RruleHelper

  before_action :require_user, except: %w[public_feed index]
  before_action :get_calendar_context, only: :create
  before_action :require_user_or_observer, only: [:user_index]
  before_action :require_authorization, only: %w[index user_index]

  RECURRING_EVENT_LIMIT = 200

  DEFAULT_INCLUDES = %w[child_events].freeze

  # @API List calendar events
  #
  # Retrieve the paginated list of calendar events or assignments for the current user
  #
  # @argument type [String, "event"|"assignment"] Defaults to "event"
  # @argument start_date [Date]
  #   Only return events since the start_date (inclusive).
  #   Defaults to today. The value should be formatted as: yyyy-mm-dd or ISO 8601 YYYY-MM-DDTHH:MM:SSZ.
  # @argument end_date [Date]
  #   Only return events before the end_date (inclusive).
  #   Defaults to start_date. The value should be formatted as: yyyy-mm-dd or ISO 8601 YYYY-MM-DDTHH:MM:SSZ.
  #   If end_date is the same as start_date, then only events on that day are
  #   returned.
  # @argument undated [Boolean]
  #   Defaults to false (dated events only).
  #   If true, only return undated events and ignore start_date and end_date.
  # @argument all_events [Boolean]
  #   Defaults to false (uses start_date, end_date, and undated criteria).
  #   If true, all events are returned, ignoring start_date, end_date, and undated criteria.
  # @argument context_codes[] [String]
  #   List of context codes of courses, groups, users, or accounts whose events you want to see.
  #   If not specified, defaults to the current user (i.e personal calendar,
  #   no course/group events). Limited to 10 context codes, additional ones are
  #   ignored. The format of this field is the context type, followed by an
  #   underscore, followed by the context id. For example: course_42
  # @argument excludes[] [Array]
  #   Array of attributes to exclude. Possible values are "description", "child_events" and "assignment"
  # @argument includes[] [Array]
  #   Array of optional attributes to include. Possible values are "web_conference" and "series_natural_language"
  # @argument important_dates [Boolean]
  #   Defaults to false.
  #   If true, only events with important dates set to true will be returned.
  # @argument blackout_date [Boolean]
  #   Defaults to false.
  #   If true, only events with blackout date set to true will be returned.
  #
  # @returns [CalendarEvent]
  def index
    render_events_for_user(@current_user, api_v1_calendar_events_url)
  end

  # @API List calendar events for a user
  #
  # Retrieve the paginated list of calendar events or assignments for the specified user.
  # To view calendar events for a user other than yourself,
  # you must either be an observer of that user or an administrator.
  #
  # @argument type [String, "event"|"assignment"] Defaults to "event"
  # @argument start_date [Date]
  #   Only return events since the start_date (inclusive).
  #   Defaults to today. The value should be formatted as: yyyy-mm-dd or ISO 8601 YYYY-MM-DDTHH:MM:SSZ.
  # @argument end_date [Date]
  #   Only return events before the end_date (inclusive).
  #   Defaults to start_date. The value should be formatted as: yyyy-mm-dd or ISO 8601 YYYY-MM-DDTHH:MM:SSZ.
  #   If end_date is the same as start_date, then only events on that day are
  #   returned.
  # @argument undated [Boolean]
  #   Defaults to false (dated events only).
  #   If true, only return undated events and ignore start_date and end_date.
  # @argument all_events [Boolean]
  #   Defaults to false (uses start_date, end_date, and undated criteria).
  #   If true, all events are returned, ignoring start_date, end_date, and undated criteria.
  # @argument context_codes[] [String]
  #   List of context codes of courses, groups, users, or accounts whose events you want to see.
  #   If not specified, defaults to the current user (i.e personal calendar,
  #   no course/group events). Limited to 10 context codes, additional ones are
  #   ignored. The format of this field is the context type, followed by an
  #   underscore, followed by the context id. For example: course_42
  # @argument excludes[] [Array]
  #   Array of attributes to exclude. Possible values are "description", "child_events" and "assignment"
  # @argument submission_types[] [Array]
  #   When type is "assignment", specifies the allowable submission types for returned assignments.
  #   Ignored if type is not "assignment" or if exclude_submission_types is provided.
  # @argument exclude_submission_types[] [Array]
  #   When type is "assignment", specifies the submission types to be excluded from the returned
  #   assignments. Ignored if type is not "assignment".
  # @argument includes[] [Array]
  #   Array of optional attributes to include. Possible values are "web_conference" and "series_natural_language"
  # @argument important_dates [Boolean]
  #   Defaults to false
  #   If true, only events with important dates set to true will be returned.
  # @argument blackout_date [Boolean]
  #   Defaults to false
  #   If true, only events with blackout date set to true will be returned.
  #
  # @returns [CalendarEvent]
  def user_index
    render_events_for_user(@observee, api_v1_user_calendar_events_url)
  end

  def render_events_for_user(user, route_url)
    GuardRail.activate(:secondary) do
      scope = if @type == :assignment
                assignment_scope(
                  user,
                  submission_types: params.fetch(:submission_types, []),
                  exclude_submission_types: params.fetch(:exclude_submission_types, [])
                )
              else
                calendar_event_scope(user)
              end

      events = Api.paginate(scope, self, route_url)
      ActiveRecord::Associations.preload(events, :child_events) if @type == :event
      if @type == :assignment
        events = apply_assignment_overrides(events, user)
        mark_submitted_assignments(user, events)
        if includes.include?("submission")
          submissions = Submission.active.where(assignment_id: events, user_id: user)
                                  .group_by(&:assignment_id)
        end
        # preload data used by assignment_json
        ActiveRecord::Associations.preload(events, :discussion_topic)
        Shard.partition_by_shard(events) do |shard_events|
          having_submission = Assignment.assignment_ids_with_submissions(shard_events.map(&:id))
          shard_events.each do |event|
            event.has_submitted_submissions = having_submission.include?(event.id)
          end

          having_student_submission = Submission.active.having_submission
                                                .where(assignment_id: shard_events)
                                                .where.not(user_id: nil)
                                                .distinct
                                                .pluck(:assignment_id).to_set
          shard_events.each do |event|
            event.has_student_submissions = having_student_submission.include?(event.id)
          end
        end
      end

      if @errors.empty?
        calendar_events, assignments = events.partition { |e| e.is_a?(CalendarEvent) }
        ActiveRecord::Associations.preload(calendar_events, [:context, :parent_event])
        ActiveRecord::Associations.preload(assignments, Api::V1::Assignment::PRELOADS)
        ActiveRecord::Associations.preload(assignments.map(&:context), %i[account grading_period_groups enrollment_term])
        log_event_count(events.count)

        json = events.map do |event|
          subs = submissions[event.id] if submissions
          sub = subs.max_by(&:submitted_at) if subs
          event_json(event, user, session, { include: includes, excludes: params[:excludes], submission: sub })
        end
        render json:
      else
        render json: { errors: @errors.as_json }, status: :bad_request
      end
    end
  end

  # @API Create a calendar event
  #
  # Create and return a new calendar event
  #
  # @argument calendar_event[context_code] [Required, String]
  #   Context code of the course, group, user, or account whose calendar
  #   this event should be added to.
  # @argument calendar_event[title] [String]
  #   Short title for the calendar event.
  # @argument calendar_event[description] [String]
  #   Longer HTML description of the event.
  # @argument calendar_event[start_at] [DateTime]
  #   Start date/time of the event.
  # @argument calendar_event[end_at] [DateTime]
  #   End date/time of the event.
  # @argument calendar_event[location_name] [String]
  #   Location name of the event.
  # @argument calendar_event[location_address] [String]
  #   Location address
  # @argument calendar_event[time_zone_edited] [String]
  #   Time zone of the user editing the event. Allowed time zones are
  #   {http://www.iana.org/time-zones IANA time zones} or friendlier
  #   {http://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html Ruby on Rails time zones}.
  # @argument calendar_event[all_day] [Boolean]
  #   When true event is considered to span the whole day and times are ignored.
  # @argument calendar_event[child_event_data][X][start_at] [DateTime]
  #   Section-level start time(s) if this is a course event. X can be any
  #   identifier, provided that it is consistent across the start_at, end_at
  #   and context_code
  # @argument calendar_event[child_event_data][X][end_at] [DateTime]
  #   Section-level end time(s) if this is a course event.
  # @argument calendar_event[child_event_data][X][context_code] [String]
  #   Context code(s) corresponding to the section-level start and end time(s).
  # @argument calendar_event[duplicate][count] [Number]
  #   Number of times to copy/duplicate the event.  Count cannot exceed 200.
  # @argument calendar_event[duplicate][interval] [Number]
  #   Defaults to 1 if duplicate `count` is set.  The interval between the duplicated events.
  # @argument calendar_event[duplicate][frequency] [String, "daily"|"weekly"|"monthly"]
  #   Defaults to "weekly".  The frequency at which to duplicate the event
  # @argument calendar_event[duplicate][append_iterator] [Boolean]
  #   Defaults to false.  If set to `true`, an increasing counter number will be appended to the event title
  #   when the event is duplicated.  (e.g. Event 1, Event 2, Event 3, etc)
  # @argument calendar_event[rrule] [string]
  #   The recurrence rule to create a series of recurring events.
  #   Its value is the {https://icalendar.org/iCalendar-RFC-5545/3-8-5-3-recurrence-rule.html iCalendar RRULE}
  #   defining how the event repeats. Unending series not supported.
  # @argument calendar_event[blackout_date] [Boolean]
  #   If the blackout_date is true, this event represents a holiday or some
  #   other special day that does not count in course pacing.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/calendar_events.json' \
  #        -X POST \
  #        -F 'calendar_event[context_code]=course_123' \
  #        -F 'calendar_event[title]=Paintball Fight!' \
  #        -F 'calendar_event[start_at]=2012-07-19T21:00:00Z' \
  #        -F 'calendar_event[end_at]=2012-07-19T22:00:00Z' \
  #        -H "Authorization: Bearer <token>"
  def create
    if @context.is_a?(Course) && @context.deleted?
      return render json: { error: t("cannot create event for deleted course") }, status: :bad_request
    end

    params_for_create = calendar_event_params
    if params_for_create[:description].present?
      params_for_create[:description] = process_incoming_html_content(params_for_create[:description])
    end
    if params_for_create.key?(:web_conference)
      web_conference_params = params_for_create[:web_conference]
      unless web_conference_params.empty?
        web_conference_params[:start_at] = params_for_create[:start_at]
        web_conference_params[:end_at] = params_for_create[:end_at]
      end
      params_for_create[:web_conference] = find_or_initialize_conference(@context, web_conference_params)
    end

    @event = @context.calendar_events.build(params_for_create)
    @event.updating_user = @current_user
    @event.validate_context! if @context.is_a?(AppointmentGroup)

    if authorized_action(@event, @current_user, :create)
      event_type_tag = nil
      rrule = params_for_create[:rrule]
      # Create multiple events if necessary
      if rrule.present?
        start_at = Time.parse(params_for_create[:start_at]) if params_for_create[:start_at]
        rr = validate_and_parse_rrule(
          rrule,
          dtstart: start_at,
          tzid: @current_user.time_zone&.tzinfo&.name || "UTC"
        )
        return false if rr.nil?

        events = create_event_series(params_for_create, rr)
        event_type_tag = "series"
      else
        events = []
        dup_options = get_duplicate_params(params[:calendar_event])

        if dup_options[:count] > RECURRING_EVENT_LIMIT
          InstStatsd::Statsd.gauge("calendar_events_api.recurring.count_exceeding_limit", dup_options[:count])
          return render json: {
                          message: t("only a maximum of %{limit} events can be created",
                                     limit: RECURRING_EVENT_LIMIT)
                        },
                        status: :bad_request
        elsif dup_options[:count] > 0
          InstStatsd::Statsd.gauge("calendar_events_api.recurring.count", dup_options[:count])
          events += create_event_and_duplicates(dup_options)
          event_type_tag = "recurring"
        else
          events = [@event]
          event_type_tag = "single"
        end
      end

      return unless events.all? { |event| authorize_user_for_conference(@current_user, event.web_conference) }

      CalendarEvent.transaction do
        error = events.detect { |event| !event.save }
        if error
          render json: error.errors, status: :bad_request
          raise ActiveRecord::Rollback
        else
          statsd_event_create_tags = @current_user.participating_enrollments.pluck(:type).uniq.map { |type| "enrollment_type:#{type}" }.append("calendar_event_type:#{event_type_tag}")
          InstStatsd::Statsd.increment("calendar.calendar_event.create", tags: statsd_event_create_tags)

          original_event = events.shift
          render json: event_json(
            original_event,
            @current_user,
            session,
            { duplicates: events, include: includes(["web_conference", "series_natural_language"]) }
          ),
                 status: :created
        end
      end
    end
  end

  # @API Get a single calendar event or assignment
  #
  # @returns CalendarEvent

  def show
    get_event(true)
    if authorized_action(@event, @current_user, :read)
      render json: event_json(@event, @current_user, session, include: includes + [:web_conference])
    end
  end

  # @API Reserve a time slot
  #
  # Reserves a particular time slot and return the new reservation
  #
  # @argument participant_id [String]
  #   User or group id for whom you are making the reservation (depends on the
  #   participant type). Defaults to the current user (or user's candidate group).
  #
  # @argument comments [String]
  #  Comments to associate with this reservation
  #
  # @argument cancel_existing [Boolean]
  #   Defaults to false. If true, cancel any previous reservation(s) for this
  #   participant and appointment group.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/calendar_events/345/reservations.json' \
  #        -X POST \
  #        -F 'cancel_existing=true' \
  #        -H "Authorization: Bearer <token>"
  def reserve
    get_event
    if authorized_action(@event, @current_user, :reserve) && check_for_past_signup(@event)
      begin
        participant_id = Shard.relative_id_for(params[:participant_id], Shard.current, Shard.current) if params[:participant_id]
        if participant_id && @event.appointment_group.grants_right?(@current_user, session, :manage)
          participant = @event.appointment_group.possible_participants.detect { |p| p.id == participant_id }
        else
          participant = @event.appointment_group.participant_for(@current_user)
          participant = nil if participant && participant_id && participant_id != participant.id
        end
        raise CalendarEvent::ReservationError, "invalid participant" unless participant

        reservation = @event.reserve_for(participant,
                                         @current_user,
                                         cancel_existing: value_to_boolean(params[:cancel_existing]),
                                         comments: params["comments"])
        render json: event_json(reservation, @current_user, session)
      rescue CalendarEvent::ReservationError => e
        reservations = participant ? @event.appointment_group.reservations_for(participant) : []
        render json: [{
          attribute: "reservation",
          type: "calendar_event",
          message: e.message,
          reservations: reservations.map { |r| event_json(r, @current_user, session) }
        }],
               status: :bad_request
      end
    end
  end

  # Pulling participants is done from the parent event that spawns the user's child calendar events
  def participants
    get_event
    if authorized_action(@event, @current_user, :read_child_events)
      return render json: [].to_json unless @event.appointment_group?

      participants = Api.paginate(@event.child_event_participants_scope.order(:id), self, api_v1_calendar_event_participants_url)
      json = participants.map do |user|
        user_display_json(user)
      end
      render json:
    end
  end

  # @API Update a calendar event
  #
  # Update and return a calendar event
  #
  # @argument calendar_event[context_code] [Optional, String]
  #   Context code of the course, group, user, or account to move this event to.
  #   Scheduler appointments and events with section-specific times cannot be moved between calendars.
  # @argument calendar_event[title] [String]
  #   Short title for the calendar event.
  # @argument calendar_event[description] [String]
  #   Longer HTML description of the event.
  # @argument calendar_event[start_at] [DateTime]
  #   Start date/time of the event.
  # @argument calendar_event[end_at] [DateTime]
  #   End date/time of the event.
  # @argument calendar_event[location_name] [String]
  #   Location name of the event.
  # @argument calendar_event[location_address] [String]
  #   Location address
  # @argument calendar_event[time_zone_edited] [String]
  #   Time zone of the user editing the event. Allowed time zones are
  #   {http://www.iana.org/time-zones IANA time zones} or friendlier
  #   {http://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html Ruby on Rails time zones}.
  # @argument calendar_event[all_day] [Boolean]
  #   When true event is considered to span the whole day and times are ignored.
  # @argument calendar_event[child_event_data][X][start_at] [DateTime]
  #   Section-level start time(s) if this is a course event. X can be any
  #   identifier, provided that it is consistent across the start_at, end_at
  #   and context_code
  # @argument calendar_event[child_event_data][X][end_at] [DateTime]
  #   Section-level end time(s) if this is a course event.
  # @argument calendar_event[child_event_data][X][context_code] [String]
  #   Context code(s) corresponding to the section-level start and end time(s).
  # @argument calendar_event[rrule] [Optional, String]
  #   Valid if the event whose ID is in the URL is part of a series.
  #   This defines the shape of the recurring event series after it's updated.
  #   Its value is the iCalendar RRULE. Unending series are not supported.
  # @argument which [Optional, String, "one"|"all"|"following"]
  #   Valid if the event whose ID is in the URL is part of a series.
  #   Update just the event whose ID is in in the URL, all events
  #   in the series, or the given event and all those following.
  #   Some updates may create a new series. For example, changing the start time
  #   of this and all following events from the middle of a series.
  # @argument calendar_event[blackout_date] [Boolean]
  #   If the blackout_date is true, this event represents a holiday or some
  #   other special day that does not count in course pacing.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/calendar_events/234' \
  #        -X PUT \
  #        -F 'calendar_event[title]=Epic Paintball Fight!' \
  #        -H "Authorization: Bearer <token>"
  def update
    get_event(true)
    if authorized_action(@event, @current_user, :update)
      params_for_update = nil
      if @event.is_a?(Assignment)
        params_for_update = { due_at: params[:calendar_event][:start_at] }
      else
        params_for_update = calendar_event_params
        @event.validate_context! if @event.context.is_a?(AppointmentGroup)
        @event.updating_user = @current_user
      end
      context_code = params[:calendar_event].delete(:context_code)
      if context_code
        context = Context.find_by_asset_string(context_code)
        raise ActiveRecord::RecordNotFound, "Invalid context_code" unless context

        if @event.context != context
          if @event.context.is_a?(AppointmentGroup)
            return render json: { message: t("Cannot move Scheduler appointments between calendars") }, status: :bad_request
          end
          if @event.parent_calendar_event_id.present? || @event.child_events.any? || @event.effective_context_code.present?
            return render json: { message: t("Cannot move events with section-specific times between calendars") }, status: :bad_request
          end

          @event.context = context
        end
        return unless authorized_action(@event, @current_user, :create)
      end
      if params_for_update[:description].present?
        params_for_update[:description] = process_incoming_html_content(params_for_update[:description])
      end
      if params_for_update.key?(:web_conference)
        web_conference_params = params_for_update[:web_conference]
        unless web_conference_params.empty?
          web_conference_params[:start_at] = params_for_update[:start_at]
          web_conference_params[:end_at] = params_for_update[:end_at]
        end
        web_conference = find_or_initialize_conference(@event.context, web_conference_params)
        return unless authorize_user_for_conference(@current_user, web_conference)

        params_for_update[:web_conference] = web_conference
      end

      if @event[:series_uuid].nil? && params_for_update[:rrule].present?
        series_event = change_to_series_event(@event, params_for_update)
        return update_from_series(series_event, params_for_update, "all")
      elsif @event[:series_uuid].present?
        return update_from_series(@event, params_for_update, params[:which])
      end

      if @event.update(params_for_update)
        render json: event_json(@event, @current_user, session, include: includes("web_conference"))
      else
        render json: @event.errors, status: :bad_request
      end
    end
  end

  # @API Delete a calendar event
  #
  # Delete an event from the calendar and return the deleted event
  #
  # @argument cancel_reason [String]
  #   Reason for deleting/canceling the event.
  # @argument which [Optional, String, "one"|"all"|"following"]
  #   Valid if the event whose ID is in the URL is part of a series.
  #   Delete just the event whose ID is in in the URL, all events
  #   in the series, or the given event and all those following.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/calendar_events/234' \
  #        -X DELETE \
  #        -F 'cancel_reason=Greendale layed off the janitorial staff :(' \
  #        -F 'which=following'
  #        -H "Authorization: Bearer <token>"
  def destroy
    get_event
    if @event.series_uuid.present?
      destroy_from_series
      return
    end
    if authorized_action(@event, @current_user, :delete) && check_for_past_signup(@event.parent_event)
      @event.updating_user = @current_user
      @event.cancel_reason = params[:cancel_reason]
      if @event.destroy
        if @event.appointment_group && @event.appointment_group.appointments.count == 0
          @event.appointment_group.destroy(@current_user)
        end
        render json: event_json(@event, @current_user, session)
      else
        render json: @event.errors, status: :bad_request
      end
    end
  end

  def destroy_from_series
    events = find_which_series_events(target_event: @event, which: params[:which], for_update: false)
    return if events.blank?

    front_half_events = []

    events.each do |event|
      return false unless authorized_action(event, @current_user, :delete) && check_for_past_signup(@event.parent_event)
    end

    error = nil
    CalendarEvent.skip_touch_context
    CalendarEvent.transaction do
      events.find_each do |event|
        event.updating_user = @current_user
        event.cancel_reason = params[:cancel_reason]
        if event.destroy
          if event.appointment_group && @event.appointment_group.appointments.count == 0
            event.appointment_group.destroy(@current_user)
          end
        else
          error = event.errors
          raise ActiveRecord::Rollback
        end
      end

      if params[:which] == "following"
        # the remaining series just got shorter. reflect that in the rrrule
        front_half_events = (find_which_series_events(target_event: @event, which: "all", for_update: false) - events).to_a
        unless front_half_events.empty?
          params_for_update_front_half = ActionController::Parameters.new(rrule: update_rrule_count_or_until(@event[:rrule], front_half_events.length)).permit(:rrule)
          front_half_events.each do |event|
            event.updating_user = @current_user
            unless event.grants_any_right?(@current_user, session, :update)
              error = { message: t("Failed updating an event in the series, update not saved"), status: :unauthorized }
              raise ActiveRecord::Rollback
            end

            unless event.update(params_for_update_front_half)
              error = { message: t("Failed updating an event in the series, update not saved") }
              raise ActiveRecord::Rollback
            end
          end
        end
      end
    end
    CalendarEvent.skip_touch_context(false)

    return render json: error, status: :bad_request if error

    @event.context.touch # assume all events in the series belong to the same context

    json = (events + front_half_events).map do |event|
      event.reload
      event_json(event, @current_user, session, include: includes(["web_conference", "series_natural_language"]))
    end
    render json:
  end

  # updating event data in a series has some tricky bits
  # 1. if which=="one"
  #    - if the rrule changed, return an error
  #    - just update it and we're finished
  # 2. if which="all"
  #    - if the date changed, return an error
  #    - get the first event in the series' start_at
  #      and use it as the dtstart when parsing the rrule,
  #    - then update each event with the new params.
  #    - You cannot use target_event (the event the user edited in the UI)
  #      because they can edit an event in the middle of the series
  #      then say update all.
  # 3. if which="following":
  #    a. if the date-time is unchanged, update the non-date-time
  #       properties with the new params foraeffected events
  #       events in the series
  #    b. if the date-time did change
  #       - start a new series for the affected events
  #       - use the start_at from the target_event
  #       - limit the dtstart dates generated by the rrule to the
  #         number of affected events.
  #       - update the RRULE for the events left behind in the original series
  #         to reflect it's new shorter length.
  #  4. If the RRULE changed, only which=="all" or "following" apply
  #     a. if which="all",
  #        - regenerate the list of dtstarts using the first event's start_at
  #        - update events we have, create more or delete leftovers if necessary
  #     b. if which="following",
  #        - start a new series for the affected events.
  #        - the same as "all", but for the subset of affected events
  #        - will split the series in two, creating a new series for the updated
  #          events, and updating the original series to reflect it's new shorter length.
  #   5. If the date-time and RRULE changed, deal with that too.
  #
  def update_from_series(target_event, params_for_update, which)
    which ||= "one"
    rrule = params_for_update.key?(:rrule) ? params_for_update[:rrule] : target_event.rrule
    rrule_changed = rrule != target_event[:rrule]
    # If a nil RRULE is explicitly passed in params and the event had a valid RRULE the series will be converted to a single event
    change_to_single_event = rrule_changed && params_for_update.key?(:rrule) && params_for_update[:rrule].blank?
    params_for_update[:rrule] ||= rrule
    params_for_update[:series_uuid] ||= target_event.series_uuid
    params_for_update[:start_at] ||= target_event.start_at.iso8601
    params_for_update[:end_at] ||= target_event.end_at.iso8601
    params_for_update[:context] = Context.find_by_asset_string(params_for_update[:context_code]) if params_for_update[:context_code]
    params_for_update.delete(:context_code)

    if which == "one" && rrule.present? && rrule_changed
      render json: { message: t("You may not update one event with a new schedule.") }, status: :bad_request
      return
    end

    all_date_change_ok = false
    if which == "all" && Time.parse(params_for_update[:start_at]).utc.to_date != target_event.start_at&.utc&.to_date
      if target_event.series_head?
        all_date_change_ok = true
      else
        render json: { message: t("You may not change the start date when changing all events in the series") }, status: :bad_request
        return
      end
    end

    if which == "one" && !change_to_single_event
      if target_event.workflow_state == "locked"
        render json: { message: t("You may not update a locked event") }, status: :bad_request
        return
      elsif target_event.update(params_for_update)
        render json: event_json(target_event, @current_user, session, include: includes(["web_conference", "series_natural_language"]))
      else
        render json: { message: t("Update failed") }, status: bad_request
      end
      return
    end

    all_events = find_which_series_events(target_event:, which: "all", for_update: true)
    adjusted_all_events = all_events.empty? ? [target_event] : all_events
    events = (which == "following") ? adjusted_all_events.where("start_at >= ?", target_event.start_at) : adjusted_all_events

    tz = @current_user.time_zone || ActiveSupport::TimeZone.new("UTC")
    target_start = Time.parse(params_for_update[:start_at]).in_time_zone(tz)
    target_end = Time.parse(params_for_update[:end_at]).in_time_zone(tz)
    if which == "all" && !all_date_change_ok
      # the target_event not be the first event in the series. We need to find it
      # as the anchor for the series dates
      start_date0 = events[0].start_at.in_time_zone(tz).to_date
      end_date0 = events[0].end_at.in_time_zone(tz).to_date

      first_start_at = Time.new(start_date0.year, start_date0.month, start_date0.day, target_start.hour, target_start.min, target_start.sec, tz)
      first_end_at = Time.new(end_date0.year, end_date0.month, end_date0.day, target_end.hour, target_end.min, target_end.sec, tz)
    else
      first_start_at = target_start
      first_end_at = target_end
      date_time_changed = Time.parse(params_for_update[:start_at]) != target_event.start_at ||
                          Time.parse(params_for_update[:end_at]) != target_event.end_at
    end
    duration = first_end_at - first_start_at

    # An RRULE is not present if the series will be converted to a single event
    rr = nil
    if rrule.present?
      rr = validate_and_parse_rrule(
        rrule,
        dtstart: first_start_at,
        tzid: tz&.tzinfo&.name || "UTC"
      )
      return false if rr.nil?
    end

    params_for_update_front_half = nil
    front_half_events = []
    if (all_events.length > events.length && date_time_changed) || rrule_changed
      # updating date-time for half a series starts a new series
      if all_events.length > events.length
        params_for_update[:rrule] = update_rrule_count(rrule, events.length) unless rrule_changed
        params_for_update[:series_uuid] = SecureRandom.uuid
        new_series_head = true

        front_half_events = (all_events - events).to_a
        params_for_update_front_half = ActionController::Parameters.new(rrule: update_rrule_count_or_until(all_events[0]["rrule"], all_events.length - events.length)).permit(:rrule)
      end
    else
      params_for_update[:series_uuid] = target_event[:series_uuid]
    end

    events = events.to_a
    update_limit = rrule_changed ? RruleHelper::RECURRING_EVENT_LIMIT : events.length

    error = nil
    CalendarEvent.skip_touch_context
    CalendarEvent.transaction do
      dtstart_list = rr.present? ? rr.all(limit: update_limit) : []
      if rr.present? && events.length > dtstart_list.length
        # truncate the list of events we're updating to how many
        # we'll end up with given the (possible updated) rrule
        events.drop(dtstart_list.length).each do |event|
          unless event.grants_any_right?(@current_user, session, :delete)
            error = { message: t("Failed deleting an event from the series, update not saved"), status: :unauthorized }
            raise ActiveRecord::Rollback
          end

          unless event.destroy
            error = { message: t("Failed deleting an event from the series, update not saved") }
            raise ActiveRecord::Rollback
          end
        end
        events = events.take(dtstart_list.length)
      end

      if new_series_head
        events[0].series_head = true
      end

      dtstart_list.each_with_index do |dtstart, i|
        params_for_update = set_series_params(params_for_update, dtstart, duration)
        event = events[i]
        if event.nil?
          event = target_event.context.calendar_events.build(params_for_update)
          events << event
          unless event.grants_any_right?(@current_user, session, :create)
            error = { message: t("Failed creating an event for the series, update not saved"), status: :unauthorized }
            raise ActiveRecord::Rollback
          end

          unless event.save
            error = { message: t("Failed creating an event for the series, update not saved") }
            raise ActiveRecord::Rollback
          end
        else
          event.updating_user = @current_user
          unless event.grants_any_right?(@current_user, session, :update)
            error = { message: t("Failed updating an event in the series, update not saved"), status: :unauthorized }
            raise ActiveRecord::Rollback
          end

          unless event.update(params_for_update)
            error = { message: t("Failed updating an event in the series, update not saved") }
            raise ActiveRecord::Rollback
          end
        end
      end

      # For convert series to single event, all the series event will be removed except the target event
      if change_to_single_event
        params_for_update[:series_head] = false
        params_for_update[:series_uuid] = nil
        params_for_update[:rrule] = nil
        unless target_event.update(params_for_update)
          error = { message: t("Failed updating an event in the series, update not saved") }
          raise ActiveRecord::Rollback
        end

        (events - [target_event]).each do |event|
          unless event.grants_any_right?(@current_user, session, :delete)
            error = { message: t("Failed deleting an event from the series, update not saved"), status: :unauthorized }
            raise ActiveRecord::Rollback
          end

          unless event.destroy
            error = { message: t("Failed deleting an event from the series, update not saved") }
            raise ActiveRecord::Rollback
          end
        end
        events = [target_event]
      end

      # if we updated this-and-all-following, we had to update the front half's rrule
      front_half_events.each do |event|
        event.updating_user = @current_user
        unless event.grants_any_right?(@current_user, session, :update)
          error = { message: t("Failed updating an event in the series, update not saved"), status: :unauthorized }
          raise ActiveRecord::Rollback
        end

        unless event.update(params_for_update_front_half)
          error = { message: t("Failed updating an event in the series, update not saved") }
          raise ActiveRecord::Rollback
        end
      end
    end
    CalendarEvent.skip_touch_context(false)

    if error
      status = error[:status] || :bad_request
      error.delete(:status)
      return render json: error, status:
    end

    target_event.context.touch
    json = (front_half_events + events).map do |event|
      event_json(
        event,
        @current_user,
        session,
        { include: includes(["web_conference", "series_natural_language"]) }
      )
    end
    render json:
  end

  def find_which_series_events(target_event:, which:, for_update:)
    which ||= "one"
    #  from the model: locked events may only be deleted, they cannot be edited directly
    workflow_state_not = for_update ? ["deleted", "locked"] : ["deleted"]
    events = nil
    case which
    when "one"
      events = CalendarEvent.where(id: target_event.id) unless for_update && target_event.workflow_state == "locked"
    when "all"
      events = CalendarEvent
               .where(series_uuid: target_event.series_uuid)
               .where.not(workflow_state: workflow_state_not)
               .order(:id)
    when "following"
      events = CalendarEvent
               .where("series_uuid = ? AND start_at >= ?", target_event.series_uuid, target_event.start_at)
               .where.not(workflow_state: workflow_state_not)
               .order(:id)
    else
      render json: { error: t("Invalid parameter which='%{which}'", which:) }, status: :bad_request
    end
    events
  end

  def change_to_series_event(event, params_for_update)
    event.series_uuid = SecureRandom.uuid
    event.series_head = true
    event.start_at = params_for_update[:start_at] if params_for_update[:start_at]
    event.end_at = params_for_update[:end_at] if params_for_update[:end_at]
    event
  end

  def public_feed
    return unless get_feed_context

    @events = []
    appointments = []

    if @current_user
      # if the feed url included the information on the requesting user,
      # we can properly filter calendar events to the user's course sections
      @type = :feed
      @start_date = 30.days.ago
      @end_date = 366.days.from_now

      get_options(nil)

      GuardRail.activate(:secondary) do
        @events.concat assignment_scope(@current_user).paginate(per_page: 1000, max: 1000)
        @events = apply_assignment_overrides(@events, @current_user)
        @events.concat calendar_event_scope(@current_user, &:events_without_child_events).paginate(per_page: 1000, max: 1000)

        # Add in any appointment groups this user can manage and someone has reserved
        appointment_codes = manageable_appointment_groups(@current_user).map(&:asset_string)
        appointment_groups = CalendarEvent.active
                                          .for_user_and_context_codes(@current_user, appointment_codes)
                                          .send(*date_scope_and_args)
                                          .events_with_child_events
                                          .to_a

        student_events = appointment_groups.map(&:child_events).flatten

        student_events.each do |appointment|
          # find the context associated with the appointment..
          event_context = @contexts.find do |context|
            effective_context_code =
              case context
              when Course
                "course_" + context.id.to_s
              when Group
                "group_" + context.id.to_s
              end
            !effective_context_code.nil? && appointment.effective_context_code.eql?(effective_context_code)
          end

          # and then find the user in that context who is associated with the event
          next if event_context.nil?

          appointment_user = event_context.users.find { |user| user.id == appointment.user_id }
          next if appointment_user.nil?

          appointments.push({ user: appointment_user.name,
                              comments: appointment.comments,
                              parent_id: appointment.parent_calendar_event_id,
                              course_name: event_context.name })
        end
        @events.concat appointment_groups
      end
    else
      # if the feed url doesn't give us the requesting user,
      # we have to just display the generic course feed
      get_all_pertinent_contexts
      GuardRail.activate(:secondary) do
        @contexts.each do |context|
          @assignments = context.assignments.active.to_a if context.respond_to?(:assignments)
          # no overrides to apply without a current user
          @events.concat context.calendar_events.active.to_a
          @events.concat @assignments || []
        end
      end
    end

    @events = @events.sort_by { |e| [e.start_at || CanvasSort::Last, Canvas::ICU.collation_key(e.title)] }

    @contexts.each do |context|
      log_asset_access(["calendar_feed", context], "calendar", "other", context: @context)
    end
    ActiveRecord::Associations.preload(@events, :context)

    respond_to do |format|
      format.ics do
        name = t("ics_title", "%{course_or_group_name} Calendar (Canvas)", course_or_group_name: @context.name)
        description = case @context
                      when Course
                        t("ics_description_course", "Calendar events for the course, %{course_name}", course_name: @context.name)
                      when Group
                        t("ics_description_group", "Calendar events for the group, %{group_name}", group_name: @context.name)
                      when User
                        t("ics_description_user", "Calendar events for the user, %{user_name}", user_name: @context.name)
                      else
                        t("ics_description", "Calendar events for %{context_name}", context_name: @context.name)
                      end

        calendar = Icalendar::Calendar.new
        # to appease Outlook
        calendar.append_custom_property("METHOD", "PUBLISH")
        calendar.append_custom_property("X-WR-CALNAME", name)
        calendar.append_custom_property("X-WR-CALDESC", description)

        # scan the descriptions for attachments
        preloaded_attachments = api_bulk_load_user_content_attachments(@events.map(&:description))
        @events.each do |event|
          ics_event =
            if event.is_a?(CalendarEvent)
              event.to_ics(in_own_calendar: false, preloaded_attachments:, user: @current_user, user_events: appointments)
            else
              event.to_ics(in_own_calendar: false, preloaded_attachments:, user: @current_user)
            end
          calendar.add_event(ics_event) if ics_event
        end

        render plain: calendar.to_ical
      end
      format.atom do
        title = t :feed_title, "%{course_or_group_name} Calendar Feed", course_or_group_name: @context.name
        link = calendar_url_for(@context)

        feed_xml = AtomFeedHelper.render_xml(title:, link:, entries: @events) do |e|
          { exclude_description: !!e.try(:locked_for?, @current_user) }
        end

        render plain: feed_xml
      end
    end
  end

  def visible_contexts
    get_context
    get_all_pertinent_contexts(include_groups: true, favorites_first: true)
    selected_contexts = @current_user.get_preference(:selected_calendar_contexts) || []

    contexts = @contexts.filter_map do |context|
      next if context.try(:concluded?)

      context_data = {
        id: context.id,
        name: context.nickname_for(@current_user),
        asset_string: context.asset_string,
        color: @current_user.custom_colors[context.asset_string],
        selected: selected_contexts.include?(context.asset_string),
        allow_observers_in_appointment_groups: context.is_a?(Course) && context.account.allow_observers_in_appointment_groups?,
        can_create_appointment_groups: context.is_a?(Course) && context.grants_right?(@current_user, session, :manage_calendar)
      }

      if context.is_a?(Course)
        context_data[:sections] = context.sections_visible_to(@current_user).map do |section|
          {
            id: section.id,
            name: section.name,
            asset_string: section.asset_string,
            selected: selected_contexts.include?(section.asset_string),
            can_create_appointment_groups: section.grants_right?(@current_user, session, :manage_calendar)
          }
        end
      end

      context_data
    end # remove any skipped contexts

    render json: { contexts: StringifyIds.recursively_stringify_ids(contexts) }
  end

  def save_selected_contexts
    @current_user.set_preference(:selected_calendar_contexts, params[:selected_contexts])
    render json: { status: "ok" }
  end

  # @API Save enabled account calendars
  #
  # Creates and updates the enabled_account_calendars and mark_feature_as_seen user preferences
  #
  # @argument mark_feature_as_seen [Optional, Boolean]
  #   Flag to mark account calendars feature as seen
  #
  # @argument enabled_account_calendars[] [Optional, Array]
  #   An array of account Ids to remember in the calendars list of the user
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/calendar_events/save_enabled_account_calendars' \
  #        -X POST \
  #        -F 'mark_feature_as_seen=true' \
  #        -F 'enabled_account_calendars[]=1' \
  #        -F 'enabled_account_calendars[]=2' \
  #        -H "Authorization: Bearer <token>"
  def save_enabled_account_calendars
    @current_user.set_preference(:account_calendar_events_seen, value_to_boolean(params[:mark_feature_as_seen])) if params.key?(:mark_feature_as_seen)

    if params.key?(:enabled_account_calendars)
      @current_user.set_preference(:enabled_account_calendars, params[:enabled_account_calendars])
      InstStatsd::Statsd.count("account_calendars.modal.enabled_calendars", params[:enabled_account_calendars].length)
    end

    render json: { status: "ok" }
  end

  # @API Set a course timetable
  #
  # Creates and updates "timetable" events for a course.
  # Can automaticaly generate a series of calendar events based on simple schedules
  # (e.g. "Monday and Wednesday at 2:00pm" )
  #
  # Existing timetable events for the course and course sections
  # will be updated if they still are part of the timetable.
  # Otherwise, they will be deleted.
  #
  # @argument timetables[course_section_id][] [Array]
  #   An array of timetable objects for the course section specified by course_section_id.
  #   If course_section_id is set to "all", events will be created for the entire course.
  #
  # @argument timetables[course_section_id][][weekdays] [String]
  #   A comma-separated list of abbreviated weekdays
  #   (Mon-Monday, Tue-Tuesday, Wed-Wednesday, Thu-Thursday, Fri-Friday, Sat-Saturday, Sun-Sunday)
  #
  # @argument timetables[course_section_id][][start_time] [String]
  #   Time to start each event at (e.g. "9:00 am")
  #
  # @argument timetables[course_section_id][][end_time] [String]
  #   Time to end each event at (e.g. "9:00 am")
  #
  # @argument timetables[course_section_id][][location_name] [Optional, String]
  #   A location name to set for each event
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/calendar_events/timetable' \
  #        -X POST \
  #        -F 'timetables[all][][weekdays]=Mon,Wed,Fri' \
  #        -F 'timetables[all][][start_time]=11:00 am' \
  #        -F 'timetables[all][][end_time]=11:50 am' \
  #        -F 'timetables[all][][location_name]=Room 237' \
  #        -H "Authorization: Bearer <token>"
  def set_course_timetable
    get_context
    if authorized_action(@context, @current_user, :manage_calendar)
      timetable_data = params[:timetables].to_unsafe_h

      builders = {}
      updated_section_ids = []
      timetable_data.each do |section_id, timetables|
        timetable_data[section_id] = Array(timetables)
        section = (section_id == "all") ? nil : api_find(@context.active_course_sections, section_id)
        updated_section_ids << section.id if section

        builder = Courses::TimetableEventBuilder.new(course: @context, course_section: section)
        builders[section_id] = builder

        builder.process_and_validate_timetables(timetables)
        if builder.errors.present?
          return render json: { errors: builder.errors }, status: :bad_request
        end
      end

      @context.timetable_data = timetable_data # so we can retrieve it later
      @context.save!

      timetable_data.each do |section_id, timetables|
        builder = builders[section_id]
        event_hashes = builder.generate_event_hashes(timetables)
        builder.process_and_validate_event_hashes(event_hashes)
        raise "error creating timetable events #{builder.errors.join(", ")}" if builder.errors.present?

        builder.delay.create_or_update_events(event_hashes) # someday we may want to make this a trackable progress job /shrug
      end

      # delete timetable events for sections missing here
      ignored_section_ids = @context.active_course_sections.where.not(id: updated_section_ids).pluck(:id)
      if ignored_section_ids.any?
        CalendarEvent.active.for_timetable.where(context_type: "CourseSection", context_id: ignored_section_ids)
                     .update_all(workflow_state: "deleted", deleted_at: Time.now.utc)
      end

      render json: { status: "ok" }
    end
  end

  # @API Get course timetable
  #
  # Returns the last timetable set by the
  # {api:CalendarEventsApiController#set_course_timetable Set a course timetable} endpoint
  #
  def get_course_timetable
    get_context
    if authorized_action(@context, @current_user, :manage_calendar)
      timetable_data = @context.timetable_data || {}
      render json: timetable_data
    end
  end

  # @API Create or update events directly for a course timetable
  #
  # Creates and updates "timetable" events for a course or course section.
  # Similar to {api:CalendarEventsApiController#set_course_timetable setting a course timetable},
  # but instead of generating a list of events based on a timetable schedule,
  # this endpoint expects a complete list of events.
  #
  # @argument course_section_id [Optional, String]
  #   Events will be created for the course section specified by course_section_id.
  #   If not present, events will be created for the entire course.
  #
  # @argument events[] [Array]
  #   An array of event objects to use.
  #
  # @argument events[][start_at] [DateTime]
  #   Start time for the event
  #
  # @argument events[][end_at] [DateTime]
  #   End time for the event
  #
  # @argument events[][location_name] [Optional, String]
  #   Location name for the event
  #
  # @argument events[][code] [Optional, String]
  #   A unique identifier that can be used to update the event at a later time
  #   If one is not specified, an identifier will be generated based on the start and end times
  #
  # @argument events[][title] [Optional, String]
  #   Title for the meeting. If not present, will default to the associated course's name
  #
  def set_course_timetable_events
    get_context
    if authorized_action(@context, @current_user, :manage_calendar)
      section = api_find(@context.active_course_sections, params[:course_section_id]) if params[:course_section_id]
      builder = Courses::TimetableEventBuilder.new(course: @context, course_section: section)

      event_hashes = params[:events].map(&:to_unsafe_h)
      event_hashes.each do |hash|
        [:start_at, :end_at].each do |key|
          hash[key] = CanvasTime.try_parse(hash[key])
        end
      end
      builder.process_and_validate_event_hashes(event_hashes)
      if builder.errors.present?
        return render json: { errors: builder.errors }, status: :bad_request
      end

      builder.delay.create_or_update_events(event_hashes)
      render json: { status: "ok" }
    end
  end

  protected

  def get_calendar_context
    @context = Context.find_by_asset_string(params[:calendar_event].delete(:context_code)) if params[:calendar_event] && params[:calendar_event][:context_code]
    raise ActiveRecord::RecordNotFound unless @context
  end

  def get_event(search_assignments = false)
    @event = if params[:id] =~ /\Aassignment_(.*)/
               raise ActiveRecord::RecordNotFound unless search_assignments

               Assignment.find($1)
             else
               CalendarEvent.find(params[:id])
             end
  end

  def date_scope_and_args(between_scope = :between)
    if @start_date
      [between_scope, @start_date, @end_date]
    else
      [:undated]
    end
  end

  def validate_dates
    @errors ||= {}
    if params[:start_date].present?
      if Api::DATE_REGEX.match?(params[:start_date])
        @start_date ||= Time.zone.parse(params[:start_date]).beginning_of_day
      elsif Api::ISO8601_REGEX.match?(params[:start_date])
        @start_date ||= Time.zone.parse(params[:start_date])
      else # params[:start_date] is not valid
        @errors[:start_date] = t(:invalid_date_or_time, "Invalid date or invalid datetime for %{attr}", attr: "start_date")
      end
    end

    if params[:end_date].present?
      if Api::DATE_REGEX.match?(params[:end_date])
        @end_date ||= Time.zone.parse(params[:end_date]).end_of_day
      elsif Api::ISO8601_REGEX.match?(params[:end_date])
        @end_date ||= Time.zone.parse(params[:end_date])
      else # params[:end_date] is not valid
        @errors[:end_date] = t(:invalid_date_or_time, "Invalid date or invalid datetime for %{attr}", attr: "end_date")
      end
    end
  end

  def get_options(codes, user = @current_user)
    @all_events = value_to_boolean(params[:all_events])
    @undated = value_to_boolean(params[:undated])
    @important_dates = value_to_boolean(params[:important_dates])
    @blackout_date = value_to_boolean(params[:blackout_date])
    if !@all_events && !@undated
      validate_dates
      @start_date ||= Time.zone.now.beginning_of_day
      @end_date ||= Time.zone.now.end_of_day
      @end_date = @start_date.end_of_day if @end_date < @start_date
    end

    @type ||= (params[:type] == "assignment") ? :assignment : :event

    @context ||= user

    # only get pertinent contexts if there is a user
    if user
      joined_codes = codes&.join(",")
      get_all_pertinent_contexts(
        include_groups: true,
        include_accounts: true,
        cross_shard: true,
        only_contexts: joined_codes,
        include_contexts: joined_codes
      )
    end

    if codes
      # add publicly accessible courses to the selected contexts
      @contexts ||= []
      pertinent_context_codes = Set.new(@contexts.map(&:asset_string))

      codes.each do |c|
        next if pertinent_context_codes.include?(c)

        context = Context.find_by_asset_string(c)
        @public_to_auth = true if context.is_a?(Course) && user && (context.public_syllabus_to_auth || context.public_syllabus || context.is_public || context.is_public_to_auth_users)
        @contexts.push context if context.is_a?(Course) && (context.is_public || context.public_syllabus || @public_to_auth)
        @contexts.push context if context.is_a?(Account) && user.associated_accounts.active.where(id: context.id, account_calendar_visible: true).exists?
      end

      # filter the contexts to only the requested contexts
      @selected_contexts = @contexts.select { |c| codes.include?(c.asset_string) }
    else
      @selected_contexts = @contexts
    end
    @context_codes = @selected_contexts.map(&:asset_string)
    @section_codes = []
    if user
      @is_admin = user.roles(@domain_root_account).include?("admin") # if we're an admin - don't try to figure out which sections we belong to; just include all of them
      @section_codes = user.section_context_codes(@context_codes, @is_admin)
    end

    if @type == :event && @start_date && user
      # pull in reservable appointment group events, if requested
      group_codes = codes.grep(/\Aappointment_group_(\d+)\z/).map { |m| m.sub(/.*_/, "").to_i }
      if group_codes.present?
        ags = AppointmentGroup
              .reservable_by(user)
              .where(id: group_codes)
              .select(:id).to_a
        @selected_contexts += ags
        @context_codes += ags.map(&:asset_string)
      end
      # include manageable appointment group events for the specified contexts
      # and dates
      ags = manageable_appointment_groups(user).to_a
      @selected_contexts += ags
      @context_codes += ags.map(&:asset_string)
    end
  end

  def assignment_scope(user, submission_types: [], exclude_submission_types: [])
    collections = []
    bookmarker = BookmarkedCollection::SimpleBookmarker.new(Assignment, :due_at, :id)
    last_scope = nil
    Shard.with_each_shard(user&.in_region_associated_shards || [Shard.current]) do
      # Fully ordering by due_at requires examining all the overrides linked and as it applies to
      # specific people, sections, etc. This applies the base assignment due_at for ordering
      # as a more sane default then natural DB order. No, it isn't perfect but much better.
      scope = assignment_context_scope(user)
      next unless scope

      scope = scope.order(:due_at, :id)
      scope = scope.active
      if exclude_submission_types.any?
        scope = scope.where.not(submission_types: exclude_submission_types)
      elsif submission_types.any?
        scope = scope.where(submission_types:)
      end
      scope = scope.send(*date_scope_and_args(:due_between_with_overrides)) unless @all_events
      scope = scope.with_important_dates if @important_dates

      last_scope = scope
      collections << [Shard.current.id, BookmarkedCollection.wrap(bookmarker, scope)]
    end

    return Assignment.none if collections.empty?
    return last_scope if collections.length == 1

    BookmarkedCollection.merge(*collections)
  end

  def assignment_context_scope(user)
    contexts = @selected_contexts.select { |c| c.is_a?(Course) && c.shard == Shard.current }
    return nil if contexts.empty?

    # contexts have to be partitioned into two groups so they can be queried effectively
    view_unpublished, other = contexts.partition { |c| c.grants_right?(user, session, :view_unpublished_items) }

    unless view_unpublished.empty?
      scope = Assignment.for_course(view_unpublished)
    end

    unless other.empty?
      scope2 = Assignment.published.for_course(other)
      scope = scope ? scope.or(scope2) : scope2
    end

    return scope if @public_to_auth || !user

    student_ids = Set.new
    student_ids << user.id
    courses_to_not_filter = Set.new

    # all assignments visible to an observers students should be visible to an observer
    user.observer_enrollments.shard(user).pluck(:course_id, :associated_user_id).each do |course_id, associated_user_id|
      if associated_user_id
        student_ids << associated_user_id
      else
        # in courses without any observed students, observers can see all published assignments
        courses_to_not_filter << course_id
      end
    end

    courses_to_filter_assignments = other.
                                    # context can sometimes be a user, so must filter those out
                                    select { |context| context.is_a? Course }
                                         .reject do |course|
      courses_to_not_filter.include?(course.id)
    end

    # in courses with diff assignments on, only show the visible assignments
    scope.filter_by_visibilities_in_given_courses(student_ids.to_a, courses_to_filter_assignments.map(&:id)).group("assignments.id")
  end

  def calendar_event_scope(user)
    scope = CalendarEvent
            .active
            .order(:start_at, :id)
    if user && !@public_to_auth
      bookmarker = BookmarkedCollection::SimpleBookmarker.new(CalendarEvent, :start_at, :id)
      scope = ShardedBookmarkedCollection.build(bookmarker, scope.shard(user.in_region_associated_shards)) do |relation|
        contexts = @selected_contexts.select { |context| context.shard == Shard.current }
        next if contexts.empty?

        context_codes = contexts.map(&:asset_string)
        relation = relation.for_user_and_context_codes(user, context_codes, user.section_context_codes(context_codes, @is_admin))
        relation = yield relation if block_given?
        relation = relation.send(*date_scope_and_args) unless @all_events
        relation = relation.with_important_dates if @important_dates
        relation = relation.with_blackout_date if @blackout_date
        if includes.include?("web_conference")
          relation = relation.preload(:web_conference)
        end
        relation
      end
    else
      scope = scope.for_context_codes(@context_codes)
      scope = scope.send(*date_scope_and_args) unless @all_events
      scope = scope.with_important_dates if @important_dates
      scope = scope.with_blackout_date if @blackout_date
    end
    scope
  end

  def search_params
    params.slice(:start_at, :end_at, :undated, :context_codes, :type)
  end

  def apply_assignment_overrides(events, user)
    ActiveRecord::Associations.preload(events, [:context, :assignment_overrides])
    events.each { |e| e.has_no_overrides = true if e.assignment_overrides.empty? }

    if AssignmentOverrideApplicator.should_preload_override_students?(events, user, "calendar_events_api")
      AssignmentOverrideApplicator.preload_assignment_override_students(events, user)
    end

    unless (params[:excludes] || []).include?("assignments")
      ActiveRecord::Associations.preload(events, [:rubric, :rubric_association])
      # improves locked_json performance

      student_events = events.reject { |e| e.context.grants_right?(user, session, :read_as_admin) }
      Assignment.preload_context_module_tags(student_events) if student_events.any?
    end

    courses_user_has_been_enrolled_in = DatesOverridable.precache_enrollments_for_multiple_assignments(events, user)
    events = events.each_with_object([]) do |assignment, assignments|
      if courses_user_has_been_enrolled_in[:student].include?(assignment.context_id)
        assignment = assignment.overridden_for(user)
        assignment.infer_all_day(Time.zone)
        assignments << assignment unless @important_dates && assignment.important_dates && assignment.due_at.nil?
      else
        dates_list = assignment.all_dates_visible_to(user,
                                                     courses_user_has_been_enrolled_in:)

        if dates_list.empty?
          assignments << assignment
          next assignments
        end

        original_dates, overridden_dates = dates_list.partition { |date| date[:base] }
        overridden_dates.each do |date|
          assignments << AssignmentOverrideApplicator.assignment_with_overrides(assignment, [date[:override]])
        end

        if original_dates.present?
          section_override_count = dates_list.count { |d| d[:set_type] == "CourseSection" }
          all_sections_overridden = section_override_count > 0 && section_override_count == assignment.context.active_section_count
          if !all_sections_overridden ||
             (assignments.empty? && courses_user_has_been_enrolled_in[:observer].include?(assignment.context_id))
            assignments << assignment
          end
        end
      end
    end

    if !@all_events && !@undated
      # Once we've got all of the possible assignments, delete anything
      # whose overrides put it outside of the current range.
      events.delete_if do |assignment|
        due_at = assignment.due_at
        due_at && (due_at > @end_date || due_at < @start_date)
      end
    end

    events
  end

  def mark_submitted_assignments(user, assignments)
    Shard.partition_by_shard(assignments) do |shard_assignments|
      submitted_ids = Submission.active.where.not(submission_type: nil)
                                .where(user_id: user, assignment_id: shard_assignments)
                                .pluck(:assignment_id)
      shard_assignments.each do |assignment|
        assignment.user_submitted = submitted_ids.include? assignment.id
      end
    end
  end

  def manageable_appointment_groups(user)
    return [] unless user

    AppointmentGroup
      .manageable_by(user, @context_codes)
      .intersecting(@start_date, @end_date).select(:id)
  end

  def duplicate(options = {})
    @context ||= @current_user

    if @current_user
      get_all_pertinent_contexts(include_groups: true)
    end

    options[:iterator] ||= 0
    event_attributes = set_duplicate_params(calendar_event_params, options)
    event = @context.calendar_events.build(event_attributes)
    event.validate_context! if @context.is_a?(AppointmentGroup)
    event.updating_user = @current_user
    event
  end

  def create_event_and_duplicates(options = {})
    events = []
    total_count = options[:count] + 1
    total_count.times do |i|
      events << duplicate({ iterator: i }.merge!(options))
    end
    events
  end

  def get_duplicate_params(event_data = {})
    duplicate_data = event_data[:duplicate] || params[:calendar_event][:duplicate]
    duplicate_data ||= {}

    {
      title: event_data[:title],
      start_at: event_data[:start_at],
      end_at: event_data[:end_at],
      child_event_data: event_data[:child_event_data],
      count: duplicate_data.fetch(:count, 0).to_i,
      interval: duplicate_data.fetch(:interval, 1).to_i,
      add_count: value_to_boolean(duplicate_data[:append_iterator]),
      frequency: duplicate_data.fetch(:frequency, "weekly")
    }
  end

  def set_duplicate_params(event_attributes, options = {})
    options[:iterator] ||= 0
    offset_interval = options[:interval] * options[:iterator]
    offset = case options[:frequency]
             when "monthly"
               offset_interval.months
             when "daily"
               offset_interval.days
             else
               offset_interval.weeks
             end

    event_attributes[:title] = "#{options[:title]} #{options[:iterator] + 1}" if options[:add_count]
    event_attributes[:start_at] = Time.zone.parse(options[:start_at]) + offset unless options[:start_at].blank?
    event_attributes[:end_at] = Time.zone.parse(options[:end_at]) + offset unless options[:end_at].blank?

    if options[:child_event_data].present?
      event_attributes[:child_event_data] = options[:child_event_data].map do |child_event|
        new_child_event = child_event.permit(:start_at, :end_at, :context_code)
        new_child_event[:start_at] = Time.zone.parse(child_event[:start_at]) + offset unless child_event[:start_at].blank?
        new_child_event[:end_at] = Time.zone.parse(child_event[:end_at]) + offset unless child_event[:end_at].blank?
        new_child_event
      end
    end

    if event_attributes.key?(:web_conference)
      override_params = { user_settings: { scheduled_date: event_attributes[:start_at] } }
      event_attributes[:web_conference] = find_or_initialize_conference(@context, event_attributes[:web_conference], override_params)
    end

    event_attributes
  end

  ###### recurring event series #######
  # once duplicate events are implemented for section events,
  # the above code can be removed
  #####################################
  def create_event_series(event_attributes, rrule)
    @context ||= @current_user
    if @current_user
      get_all_pertinent_contexts(include_groups: true)
    end
    event_attributes[:series_uuid] = SecureRandom.uuid

    first_start_at = Time.parse(event_attributes[:start_at]) if event_attributes[:start_at]
    first_end_at = Time.parse(event_attributes[:end_at]) if event_attributes[:end_at]
    duration = first_end_at - first_start_at if first_start_at && first_end_at
    dtstart_list = rrule.all(limit: RruleHelper::RECURRING_EVENT_LIMIT)

    InstStatsd::Statsd.gauge("calendar_events_api.recurring.count", dtstart_list.length)

    events = dtstart_list.map do |dtstart|
      event_attributes = set_series_params(event_attributes, dtstart, duration)
      event = @context.calendar_events.build(event_attributes)
      event.validate_context! if @context.is_a?(AppointmentGroup)
      event.updating_user = @current_user
      event
    end
    events[0][:series_head] = true
    events
  end

  def set_series_params(event_attributes, dtstart, duration)
    duration ||= 0
    event_attributes[:start_at] = dtstart.iso8601 if dtstart
    event_attributes[:end_at] = (dtstart + duration).iso8601 if dtstart

    # I don't know how we'd handle child events of a series
    if event_attributes[:child_event_data].present?
      return render json: { error: t("recurring events cannot have child events") }, status: :bad_request
    end

    if event_attributes.key?(:web_conference)
      override_params = { user_settings: { scheduled_date: event_attributes[:start_at] } }
      event_attributes[:web_conference] = find_or_initialize_conference(@context, event_attributes[:web_conference], override_params)
    end

    event_attributes
  end

  def validate_and_parse_rrule(rrule, dtstart: nil, tzid: "UTC")
    rr = nil
    # Though we can use the RRule::Rule below to determine if COUNT is too large
    # it's initialization can take a long time and periodically fails specs.
    # Let's do a quick check here first and abandon the request if too large.
    # We still need to check later because the RRULE could be "until some date"
    # and not an explicit count.
    rrule_fields = rrule_parse(rrule)
    begin
      rrule_validate_common_opts(rrule_fields)
    rescue RruleValidationError => e
      render json: { message: e.message }, status: :bad_request
      return nil
    end

    begin
      rr = RRule::Rule.new(
        rrule,
        dtstart:,
        tzid:
      )
    rescue => e
      render json: {
               message: t("Failed parsing the event's recurrence rule: %{e}", e:)
             },
             status: :bad_request
      return nil
    end
    # If RRULE generates a lot of events, rr.count can take a very long time to compute.
    # Asking it for 1 too many results is fast and gets the job done
    if rr.all(limit: RruleHelper::RECURRING_EVENT_LIMIT + 1).length > RruleHelper::RECURRING_EVENT_LIMIT
      InstStatsd::Statsd.gauge("calendar_events_api.recurring.count_exceeding_limit", rr.count)
      render json: {
               message: t("A maximum of %{limit} events may be created",
                          limit: RruleHelper::RECURRING_EVENT_LIMIT)
             },
             status: :bad_request
      return nil
    end
    rr
  end

  def require_user_or_observer
    return render_unauthorized_action unless @current_user.present?

    @observee = api_find(User, params[:user_id])

    if @observee.grants_right?(@current_user, session, :read)
      true # parent or admin
    else
      # possibly an observer without a full link
      shards = @current_user.in_region_associated_shards & @observee.in_region_associated_shards
      @observed_course_ids = @current_user.observer_enrollments.shard(shards).active_or_pending.where(associated_user_id: @observee).pluck(:course_id)
      if @observed_course_ids.any?
        true
      else
        render_unauthorized_action
      end
    end
  end

  def require_authorization
    @errors = {}
    user = @observee || @current_user
    # appointment groups show up here in find-appointment mode; give them a free ride
    ag_count = (params[:context_codes] || []).count { |code| code.start_with?("appointment_group_") }
    context_limit = @domain_root_account.settings[:calendar_contexts_limit] || 10
    codes = (params[:context_codes] || [user.asset_string])[0, context_limit + ag_count]
    # also accept a more compact comma-separated list of appointment group ids
    if params[:appointment_group_ids].present? && params[:appointment_group_ids].is_a?(String)
      codes += params[:appointment_group_ids].split(",").map { |id| "appointment_group_#{id}" }
    end
    get_options(codes, user)

    # if specific context codes were requested, ensure the user can access them
    if codes.present?
      selected_context_codes = Set.new(@context_codes)
      codes.each do |c|
        unless selected_context_codes.include?(c)
          render_unauthorized_action
          break
        end
      end
    else
      # otherwise, ensure there is a user provided
      unless user
        redirect_to_login
      end
    end
  end

  def calendar_event_params
    params.require(:calendar_event)
          .permit(CalendarEvent.permitted_attributes + [child_event_data: strong_anything, web_conference: strong_anything])
  end

  def check_for_past_signup(event)
    if event && event.end_at < Time.now.utc && event.context.is_a?(AppointmentGroup) &&
       !event.context.grants_right?(@current_user, :manage)
      render json: { message: t("Cannot create or change reservation for past appointment") }, status: :forbidden
      return false
    end
    true
  end

  def includes(keys = params[:include])
    (Array(keys) + DEFAULT_INCLUDES).uniq - (params[:excludes] || [])
  end

  def log_event_count(event_count)
    # Sometimes the API returns more events than the per_page limit because an assignment
    # event might have multiple assignment overrides, and overrides aren't counted toward
    # the limit. We're tracking to see how often this happens.
    per_page = Api.per_page_for(self)
    if event_count > per_page
      InstStatsd::Statsd.increment("calendar.events_api.per_page_exceeded.count")
      InstStatsd::Statsd.count("calendar.events_api.per_page_exceeded.value", event_count)
    end
  end

  def update_rrule_count(old_rrule, new_count)
    old_rrule.sub(/(COUNT=)(\d+)/, "\\1#{new_count}")
  end

  def update_rrule_count_or_until(old_rrule, new_count)
    if old_rrule.include?("COUNT")
      update_rrule_count(old_rrule, new_count)
    else
      # I feel a little hinky about replacing UNTIL with a COUNT
      # We could use rr.all(limie: new_count) and grab the last
      # one's date as the UNTIL, but this is simpler and I like simple
      old_rrule.gsub(/UNTIL=[^;]+/, "COUNT=#{new_count}")
    end
  end
end
