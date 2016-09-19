#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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

require 'atom'

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
#           "description": "the context code of the calendar this event belongs to (course, user or group)",
#           "example": "course_123",
#           "type": "string"
#         },
#         "effective_context_code": {
#           "description": "if specified, it indicates which calendar this event should be displayed on. for example, a section-level event would have the course's context code here, while the section's context code would be returned above)",
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
#         }
#       }
#     }
#
class CalendarEventsApiController < ApplicationController
  include Api::V1::CalendarEvent

  before_filter :require_user, :except => %w(public_feed index)
  before_filter :get_calendar_context, :only => :create
  before_filter :require_user_or_observer, :only => [:user_index]
  before_filter :require_authorization, :only => %w(index user_index)

  # @API List calendar events
  #
  # Retrieve the list of calendar events or assignments for the current user
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
  #   List of context codes of courses/groups/users whose events you want to see.
  #   If not specified, defaults to the current user (i.e personal calendar,
  #   no course/group events). Limited to 10 context codes, additional ones are
  #   ignored. The format of this field is the context type, followed by an
  #   underscore, followed by the context id. For example: course_42
  # @argument excludes[] [Array]
  #   Array of attributes to exclude. Possible values are "description", "child_events" and "assignment"
  #
  # @returns [CalendarEvent]
  def index
    render_events_for_user(@current_user, api_v1_calendar_events_url)
  end

  # @API List calendar events for a user
  #
  # Retrieve the list of calendar events or assignments for the specified user.
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
  #   List of context codes of courses/groups/users whose events you want to see.
  #   If not specified, defaults to the current user (i.e personal calendar,
  #   no course/group events). Limited to 10 context codes, additional ones are
  #   ignored. The format of this field is the context type, followed by an
  #   underscore, followed by the context id. For example: course_42
  # @argument excludes[] [Array]
  #   Array of attributes to exclude. Possible values are "description", "child_events" and "assignment"
  #
  # @returns [CalendarEvent]
  def user_index
    render_events_for_user(@observee, api_v1_user_calendar_events_url)
  end

  def render_events_for_user(user, route_url)
    scope = @type == :assignment ? assignment_scope(user) : calendar_event_scope(user)
    events = Api.paginate(scope, self, route_url)
    ActiveRecord::Associations::Preloader.new.preload(events, :child_events) if @type == :event
    if @type == :assignment
      events = apply_assignment_overrides(events, user)
      mark_submitted_assignments(user, events)
      includes = Array(params[:include])
      if includes.include?("submission")
        submissions = Submission.where(assignment_id: events, user_id: user)
          .group_by(&:assignment_id)
      end
      # preload data used by assignment_json
      ActiveRecord::Associations::Preloader.new.preload(events, :discussion_topic)
      Shard.partition_by_shard(events) do |shard_events|
        having_submission = Submission.having_submission.
            where(assignment_id: shard_events).
            uniq.
            pluck(:assignment_id).to_set
        shard_events.each do |event|
          event.has_submitted_submissions = having_submission.include?(event.id)
        end

        having_student_submission = Submission.having_submission.
            where(assignment_id: shard_events).
            where.not(user_id: nil).
            uniq.
            pluck(:assignment_id).to_set
        shard_events.each do |event|
          event.has_student_submissions = having_student_submission.include?(event.id)
        end
      end
    end

    if @errors.empty?
      json = events.map do |event|
        subs = submissions[event.id] if submissions
        sub = subs.sort_by(&:submitted_at).last if subs
        event_json(event, user, session, {excludes: params[:excludes], submission: sub})
      end
      render :json => json
    else
      render json: {errors: @errors.as_json}, status: :bad_request
    end
  end

  # @API Create a calendar event
  #
  # Create and return a new calendar event
  #
  # @argument calendar_event[context_code] [Required, String]
  #   Context code of the course/group/user whose calendar this event should be
  #   added to.
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
  # @argument calendar_event[child_event_data][X][start_at] [DateTime]
  #   Section-level start time(s) if this is a course event. X can be any
  #   identifier, provided that it is consistent across the start_at, end_at
  #   and context_code
  # @argument calendar_event[child_event_data][X][end_at] [DateTime]
  #   Section-level end time(s) if this is a course event.
  # @argument calendar_event[child_event_data][X][context_code] [String]
  #   Context code(s) corresponding to the section-level start and end time(s).
  # @argument calendar_event[duplicate][count] [Number]
  #   Number of times to copy/duplicate the event.
  # @argument calendar_event[duplicate][interval] [Number]
  #   Defaults to 1 if duplicate `count` is set.  The interval between the duplicated events.
  # @argument calendar_event[duplicate][frequency] [String, "daily"|"weekly"|"monthly"]
  #   Defaults to "weekly".  The frequency at which to duplicate the event
  # @argument calendar_event[duplicate][append_iterator] [Boolean]
  #   Defaults to false.  If set to `true`, an increasing counter number will be appended to the event title
  #   when the event is duplicated.  (e.g. Event 1, Event 2, Event 3, etc)
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
    if params[:calendar_event][:description].present?
      params[:calendar_event][:description] = process_incoming_html_content(params[:calendar_event][:description])
    end

    @event = @context.calendar_events.build(params[:calendar_event])
    @event.updating_user = @current_user
    @event.validate_context! if @context.is_a?(AppointmentGroup)

    if authorized_action(@event, @current_user, :create)
      # Create duplicates if necessary
      events = []
      dup_options = get_duplicate_params(params[:calendar_event])
      title = dup_options[:title]

      if dup_options[:count] > 0
        events += create_event_and_duplicates(dup_options)
      else
        events = [@event]
      end

      if dup_options[:count] > 100
        return render :json => {
                        message: t("only a maximum of 100 events can be created")
                      }, :status => :bad_request
      end

      CalendarEvent.transaction do
        error = events.detect { |event| !event.save }

        if error
          render :json => error.errors, :status => :bad_request
          raise ActiveRecord::Rollback
        else
          original_event = events.shift
          render :json => event_json(
            original_event,
            @current_user,
            session, { :duplicates => events }), :status => :created
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
      render :json => event_json(@event, @current_user, session)
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
    if authorized_action(@event, @current_user, :reserve)
      begin
        participant_id = Shard.relative_id_for(params[:participant_id], Shard.current, Shard.current) if params[:participant_id]
        if participant_id && @event.appointment_group.grants_right?(@current_user, session, :manage)
          participant = @event.appointment_group.possible_participants.detect { |p| p.id == participant_id }
        else
          participant = @event.appointment_group.participant_for(@current_user)
          participant = nil if participant && participant_id && participant_id != participant.id
        end
        raise CalendarEvent::ReservationError, "invalid participant" unless participant
        reservation = @event.reserve_for(participant, @current_user,
                                          cancel_existing: value_to_boolean(params[:cancel_existing]),
                                          comments: params['comments']
                                        )
        render :json => event_json(reservation, @current_user, session)
      rescue CalendarEvent::ReservationError => err
        reservations = participant ? @event.appointment_group.reservations_for(participant) : []
        render :json => [{
                           :attribute => 'reservation',
                           :type => 'calendar_event',
                           :message => err.message,
                           :reservations => reservations.map { |r| event_json(r, @current_user, session) }
                         }],
               :status => :bad_request
      end
    end
  end

  # @API Update a calendar event
  #
  # Update and return a calendar event
  #
  # @argument calendar_event[context_code] [Optional, String]
  #   Context code of the course/group/user to move this event to.
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
  # @argument calendar_event[child_event_data][X][start_at] [DateTime]
  #   Section-level start time(s) if this is a course event. X can be any
  #   identifier, provided that it is consistent across the start_at, end_at
  #   and context_code
  # @argument calendar_event[child_event_data][X][end_at] [DateTime]
  #   Section-level end time(s) if this is a course event.
  # @argument calendar_event[child_event_data][X][context_code] [String]
  #   Context code(s) corresponding to the section-level start and end time(s).
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/calendar_events/234.json' \
  #        -X PUT \
  #        -F 'calendar_event[title]=Epic Paintball Fight!' \
  #        -H "Authorization: Bearer <token>"
  def update
    get_event(true)
    if authorized_action(@event, @current_user, :update)
      if @event.is_a?(Assignment)
        params[:calendar_event] = {:due_at => params[:calendar_event][:start_at]}
      else
        @event.validate_context! if @event.context.is_a?(AppointmentGroup)
        @event.updating_user = @current_user
      end
      context_code = params[:calendar_event].delete(:context_code)
      if context_code
        context = Context.find_by_asset_string(context_code)
        raise ActiveRecord::RecordNotFound, "Invalid context_code" unless context
        if @event.context != context
          if @event.context.is_a?(AppointmentGroup)
            return render :json => { :message => 'Cannot move Scheduler appointments between calendars' }, :status => :bad_request
          end
          if @event.parent_calendar_event_id.present? || @event.child_events.any? || @event.effective_context_code.present?
            return render :json => { :message => 'Cannot move events with section-specific times between calendars' }, :status => :bad_request
          end
          @event.context = context
        end
        return unless authorized_action(@event, @current_user, :create)
      end
      if params[:calendar_event][:description].present?
        params[:calendar_event][:description] = process_incoming_html_content(params[:calendar_event][:description])
      end
      if @event.update_attributes(params[:calendar_event])
        render :json => event_json(@event, @current_user, session)
      else
        render :json => @event.errors, :status => :bad_request
      end
    end
  end

  # @API Delete a calendar event
  #
  # Delete an event from the calendar and return the deleted event
  #
  # @argument cancel_reason [String]
  #   Reason for deleting/canceling the event.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/calendar_events/234.json' \
  #        -X DELETE \
  #        -F 'cancel_reason=Greendale layed off the janitorial staff :(' \
  #        -H "Authorization: Bearer <token>"
  def destroy
    get_event
    if authorized_action(@event, @current_user, :delete)
      @event.updating_user = @current_user
      @event.cancel_reason = params[:cancel_reason]
      if @event.destroy
        render :json => event_json(@event, @current_user, session)
      else
        render :json => @event.errors, :status => :bad_request
      end
    end
  end

  def public_feed
    return unless get_feed_context
    @events = []

    if @current_user
      # if the feed url included the information on the requesting user,
      # we can properly filter calendar events to the user's course sections
      @type = :feed
      @start_date = Setting.get('calendar_feed_previous_days', '30').to_i.days.ago
      @end_date = Setting.get('calendar_feed_upcoming_days', '366').to_i.days.from_now

      get_options(nil)

      Shackles.activate(:slave) do
        @events.concat assignment_scope(@current_user).to_a
        @events = apply_assignment_overrides(@events, @current_user)
        @events.concat calendar_event_scope(@current_user).events_without_child_events.to_a

        # Add in any appointment groups this user can manage and someone has reserved
        appointment_codes = manageable_appointment_group_codes(@current_user)
        @events.concat CalendarEvent.active.
                         for_user_and_context_codes(@current_user, appointment_codes).
                         send(*date_scope_and_args).
                         events_with_child_events.
                         to_a
      end
    else
      # if the feed url doesn't give us the requesting user,
      # we have to just display the generic course feed
      get_all_pertinent_contexts
      Shackles.activate(:slave) do
        @contexts.each do |context|
          @assignments = context.assignments.active.to_a if context.respond_to?("assignments")
          # no overrides to apply without a current user
          @events.concat context.calendar_events.active.to_a
          @events.concat @assignments || []
        end
      end
    end

    @events = @events.sort_by { |e| [e.start_at || CanvasSort::Last, Canvas::ICU.collation_key(e.title)] }

    @contexts.each do |context|
      log_asset_access([ "calendar_feed", context ], "calendar", 'other')
    end
    ActiveRecord::Associations::Preloader.new.preload(@events, :context)

    respond_to do |format|
      format.ics do
        name = t('ics_title', "%{course_or_group_name} Calendar (Canvas)", :course_or_group_name => @context.name)
        description = case
                        when @context.is_a?(Course)
                          t('ics_description_course', "Calendar events for the course, %{course_name}", :course_name => @context.name)
                        when @context.is_a?(Group)
                          t('ics_description_group', "Calendar events for the group, %{group_name}", :group_name => @context.name)
                        when @context.is_a?(User)
                          t('ics_description_user', "Calendar events for the user, %{user_name}", :user_name => @context.name)
                        else
                          t('ics_description', "Calendar events for %{context_name}", :context_name => @context.name)
                      end

        calendar = Icalendar::Calendar.new
        # to appease Outlook
        calendar.custom_property("METHOD", "PUBLISH")
        calendar.custom_property("X-WR-CALNAME", name)
        calendar.custom_property("X-WR-CALDESC", description)

        # scan the descriptions for attachments
        preloaded_attachments = api_bulk_load_user_content_attachments(@events.map(&:description))
        @events.each do |event|
          ics_event = event.to_ics(in_own_calendar: false, preloaded_attachments: preloaded_attachments, user: @current_user)
          calendar.add_event(ics_event) if ics_event
        end

        render :text => calendar.to_ical
      end
      format.atom do
        feed = Atom::Feed.new do |f|
          f.title = t :feed_title, "%{course_or_group_name} Calendar Feed", :course_or_group_name => @context.name
          f.links << Atom::Link.new(:href => calendar_url_for(@context), :rel => 'self')
          f.updated = Time.now
          f.id = calendar_url_for(@context)
        end
        @events.each do |e|
          feed.entries << e.to_atom
        end
        render :text => feed.to_xml
      end
    end
  end

  def visible_contexts
    get_context
    get_all_pertinent_contexts(include_groups: true, favorites_first: true)
    selected_contexts = @current_user.preferences[:selected_calendar_contexts] || []

    contexts = @contexts.map do |context|
      {
        id: context.id,
        name: context.nickname_for(@current_user),
        asset_string: context.asset_string,
        color: @current_user.custom_colors[context.asset_string],
        selected: selected_contexts.include?(context.asset_string)
      }
    end

    render json: {contexts: StringifyIds.recursively_stringify_ids(contexts)}
  end

  def save_selected_contexts
    @current_user.preferences[:selected_calendar_contexts] = params[:selected_contexts]
    @current_user.save!
    render json: {status: 'ok'}
  end

  # @API Set a course timetable
  # @beta
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
      timetable_data = params[:timetables]

      builders = {}
      updated_section_ids = []
      timetable_data.each do |section_id, timetables|
        timetable_data[section_id] = Array(timetables)
        section = section_id == 'all' ? nil : api_find(@context.active_course_sections, section_id)
        updated_section_ids << section.id if section

        builder = Courses::TimetableEventBuilder.new(course: @context, course_section: section)
        builders[section_id] = builder

        builder.process_and_validate_timetables(timetables)
        if builder.errors.present?
          return render :json => {:errors => builder.errors}, :status => :bad_request
        end
      end

      @context.timetable_data = timetable_data # so we can retrieve it later
      @context.save!

      timetable_data.each do |section_id, timetables|
        builder = builders[section_id]
        event_hashes = builder.generate_event_hashes(timetables)
        builder.process_and_validate_event_hashes(event_hashes)
        raise "error creating timetable events #{builder.errors.join(", ")}" if builder.errors.present?
        builder.send_later(:create_or_update_events, event_hashes) # someday we may want to make this a trackable progress job /shrug
      end

      # delete timetable events for sections missing here
      ignored_section_ids = @context.active_course_sections.where.not(:id => updated_section_ids).pluck(:id)
      if ignored_section_ids.any?
        CalendarEvent.active.for_timetable.where(:context_type => "CourseSection", :context_id => ignored_section_ids).
          update_all(:workflow_state => 'deleted', :deleted_at => Time.now.utc)
      end

      render :json => {:status => 'ok'}
    end
  end

  # @API Get course timetable
  # @beta
  #
  # Returns the last timetable set by the
  # {api:CalendarEventsApiController#set_course_timetable Set a course timetable} endpoint
  #
  def get_course_timetable
    get_context
    if authorized_action(@context, @current_user, :manage_calendar)
      timetable_data = @context.timetable_data || {}
      render :json => timetable_data
    end
  end

  # @API Create or update events directly for a course timetable
  # @beta
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
  def set_course_timetable_events
    get_context
    if authorized_action(@context, @current_user, :manage_calendar)
      section = api_find(@context.active_course_sections, params[:course_section_id]) if params[:course_section_id]
      builder = Courses::TimetableEventBuilder.new(course: @context, course_section: section)

      event_hashes = params[:events]
      event_hashes.each do |hash|
        [:start_at, :end_at].each do |key|
          hash[key] = CanvasTime.try_parse(hash[key])
        end
      end
      builder.process_and_validate_event_hashes(event_hashes)
      if builder.errors.present?
        return render :json => {:errors => builder.errors}, :status => :bad_request
      end

      builder.send_later(:create_or_update_events, event_hashes)
      render json: {status: 'ok'}
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
      if params[:start_date] =~ Api::DATE_REGEX
        @start_date ||= Time.zone.parse(params[:start_date]).beginning_of_day
      elsif params[:start_date] =~ Api::ISO8601_REGEX
        @start_date ||= Time.zone.parse(params[:start_date])
      else # params[:start_date] is not valid
        @errors[:start_date] = t(:invalid_date_or_time, 'Invalid date or invalid datetime for %{attr}', attr: 'start_date')
      end
    end

    if params[:end_date].present?
      if params[:end_date] =~ Api::DATE_REGEX
        @end_date ||= Time.zone.parse(params[:end_date]).end_of_day
      elsif params[:end_date] =~ Api::ISO8601_REGEX
        @end_date ||= Time.zone.parse(params[:end_date])
      else # params[:end_date] is not valid
        @errors[:end_date] =  t(:invalid_date_or_time, 'Invalid date or invalid datetime for %{attr}', attr: 'end_date')
      end
    end
  end

  def get_options(codes, user = @current_user)
    @all_events = value_to_boolean(params[:all_events])
    @undated = value_to_boolean(params[:undated])
    if !@all_events && !@undated
      validate_dates
      @start_date ||= Time.zone.now.beginning_of_day
      @end_date ||= Time.zone.now.end_of_day
      @end_date = @start_date.end_of_day if @end_date < @start_date
    end

    @type ||= params[:type] == 'assignment' ? :assignment : :event

    @context ||= user

    # only get pertinent contexts if there is a user
    if user
      joined_codes = codes && codes.join(",")
      get_all_pertinent_contexts(include_groups: true, only_contexts: joined_codes, include_contexts: joined_codes)
    end

    if codes
      # add publicly accessible courses to the selected contexts
      @contexts ||= []
      pertinent_context_codes = Set.new @contexts.map { |c| c.asset_string }

      codes.each do |c|
        unless pertinent_context_codes.include?(c)
          context = Context.find_by_asset_string(c)
          @public_to_auth = true if context.is_a?(Course) && user && (context.public_syllabus_to_auth  || context.public_syllabus || context.is_public || context.is_public_to_auth_users)
          @contexts.push context if context.is_a?(Course) && (context.is_public || context.public_syllabus || @public_to_auth)
        end
      end

      # filter the contexts to only the requested contexts
      selected_contexts = @contexts.select { |c| codes.include?(c.asset_string) }
    else
      selected_contexts = @contexts
    end
    @context_codes = selected_contexts.map(&:asset_string)
    @section_codes = []
    if user
      @section_codes = user.section_context_codes(@context_codes)
    end

    if @type == :event && @start_date && user
      # pull in reservable appointment group events, if requested
      group_codes = codes.grep(/\Aappointment_group_(\d+)\z/).map { |m| m.sub(/.*_/, '').to_i }
      if group_codes.present?
        @context_codes += AppointmentGroup.
          reservable_by(user).
          intersecting(@start_date, @end_date).
          where(id: group_codes).
          map(&:asset_string)
      end
      # include manageable appointment group events for the specified contexts
      # and dates
      @context_codes += manageable_appointment_group_codes(user)
    end
  end

  def assignment_scope(user)
    # Fully ordering by due_at requires examining all the overrides linked and as it applies to
    # specific people, sections, etc. This applies the base assignment due_at for ordering
    # as a more sane default then natural DB order. No, it isn't perfect but much better.
    scope = assignment_context_scope(user).active.order_by_base_due_at.order('assignments.id ASC')

    scope = scope.send(*date_scope_and_args(:due_between_with_overrides)) unless @all_events
    scope
  end

  def assignment_context_scope(user)
    # contexts have to be partitioned into two groups so they can be queried effectively
    contexts = @contexts.select { |c| @context_codes.include?(c.asset_string) }
    view_unpublished, other = contexts.partition { |c| c.grants_right?(user, session, :view_unpublished_items) }

    sql = []
    conditions = []
    unless view_unpublished.empty?
      sql << '(assignments.context_code IN (?))'
      conditions << view_unpublished.map(&:asset_string)
    end

    unless other.empty?
      sql << '(assignments.context_code IN (?) AND assignments.workflow_state = ?)'
      conditions << other.map(&:asset_string)
      conditions << 'published'
    end

    scope = Assignment.where([sql.join(' OR ')] + conditions)
    return scope if @public_to_auth || !user

    student_ids = [user.id]
    courses_to_not_filter = []

    # all assignments visible to an observers students should be visible to an observer
    user.observer_enrollments.shard(user).each do |e|
      course_student_ids = ObserverEnrollment.observed_student_ids(e.course, user)
      if course_student_ids.any?
        student_ids.concat course_student_ids
      else
        # in courses without any observed students, observers can see all published assignments
        courses_to_not_filter << e.course_id
      end
    end

    courses_to_filter_assignments = other.
      # context can sometimes be a user, so must filter those out
      select{|context| context.is_a? Course }.
      reject{|course|
       courses_to_not_filter.include?(course.id)
      }

    # in courses with diff assignments on, only show the visible assignments
    scope = scope.filter_by_visibilities_in_given_courses(student_ids, courses_to_filter_assignments.map(&:id))
    scope
  end

  def calendar_event_scope(user)
    scope = CalendarEvent.active.order_by_start_at.order(:id)
    if user && !@public_to_auth
      scope = scope.for_user_and_context_codes(user, @context_codes, @section_codes)
    else
      scope = scope.for_context_codes(@context_codes)
    end

    scope = scope.send(*date_scope_and_args) unless @all_events
    scope
  end

  def search_params
    params.slice(:start_at, :end_at, :undated, :context_codes, :type)
  end

  def apply_assignment_overrides(events, user)
    ActiveRecord::Associations::Preloader.new.preload(events, [:context, :assignment_overrides])
    events.each { |e| e.has_no_overrides = true if e.assignment_overrides.size == 0 }

    if AssignmentOverrideApplicator.should_preload_override_students?(events, user, "calendar_events_api")
      AssignmentOverrideApplicator.preload_assignment_override_students(events, user)
    end

    unless (params[:excludes] || []).include?('assignments')
      ActiveRecord::Associations::Preloader.new.preload(events, [:rubric, :rubric_association])
      # improves locked_json performance

      student_events = events.select{|e| !e.context.grants_right?(user, session, :read_as_admin)}
      Assignment.preload_context_module_tags(student_events) if student_events.any?
    end

    courses_user_has_been_enrolled_in = DatesOverridable.precache_enrollments_for_multiple_assignments(events, user)
    events = events.inject([]) do |assignments, assignment|

      if courses_user_has_been_enrolled_in[:student].include?(assignment.context_id)
        assignment = assignment.overridden_for(user)
        assignment.infer_all_day
        assignments << assignment
      else
        dates_list = assignment.all_dates_visible_to(user,
          courses_user_has_been_enrolled_in: courses_user_has_been_enrolled_in)

        if dates_list.empty?
          assignments << assignment
          next assignments
        end

        original_dates, overridden_dates = dates_list.partition { |date| date[:base] }
        overridden_dates.each do |date|
          assignments << AssignmentOverrideApplicator.assignment_with_overrides(assignment, [date[:override]])
        end

        if original_dates.present?
          section_override_count = dates_list.count{|d| d[:set_type] == 'CourseSection'}
          all_sections_overridden = section_override_count > 0 && section_override_count == assignment.context.active_section_count
          if !all_sections_overridden ||
              (assignments.empty? && courses_user_has_been_enrolled_in[:observer].include?(assignment.context_id))
            assignments << assignment
          end
        end
      end
      assignments
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
    submitted_ids = Submission.where("submission_type IS NOT NULL").
      where(user_id: user, assignment_id: assignments).
      pluck(:assignment_id)
    assignments.each do |assignment|
      assignment.user_submitted = submitted_ids.include? assignment.id
    end
  end

  def manageable_appointment_group_codes(user)
    return [] unless user

    AppointmentGroup.
      manageable_by(user, @context_codes).
      intersecting(@start_date, @end_date).
      pluck(:id).map{|id| "appointment_group_#{id}"}
  end

  def duplicate(options = {})
    @context ||= @current_user

    if @current_user
      get_all_pertinent_contexts(include_groups: true)
    end

    options[:iterator] ||= 0
    event_attributes = set_duplicate_params(params[:calendar_event], options)
    event = @context.calendar_events.build(event_attributes)
    event.validate_context! if @context.is_a?(AppointmentGroup)
    event.updating_user = @current_user
    event
  end

  def create_event_and_duplicates(options = {})
    events = []
    total_count = options[:count] + 1
    total_count.times do |i|
      events << duplicate({iterator: i}.merge!(options))
    end
    events
  end

  def get_duplicate_params(event_data = {})
    duplicate_data = params[:calendar_event][:duplicate]
    duplicate_data ||= {}

    {
        title:     event_data[:title],
        start_at:  event_data[:start_at],
        end_at:    event_data[:end_at],
        child_event_data: event_data[:child_event_data],
        count:     duplicate_data.fetch(:count, 0).to_i,
        interval:  duplicate_data.fetch(:interval, 1).to_i,
        add_count: value_to_boolean(duplicate_data[:append_iterator]),
        frequency: duplicate_data.fetch(:frequency, "weekly")
    }
  end

  def set_duplicate_params(event_attributes, options = {})
    options[:iterator] ||= 0
    offset_interval = options[:interval] * options[:iterator]
    offset = if options[:frequency] == "monthly"
               offset_interval.months
             elsif options[:frequency] == "daily"
               offset_interval.days
             else
               offset_interval.weeks
             end

    event_attributes[:title] = "#{options[:title]} #{options[:iterator] + 1}" if options[:add_count]
    event_attributes[:start_at] = Time.zone.parse(options[:start_at]) + offset unless options[:start_at].blank?
    event_attributes[:end_at] = Time.zone.parse(options[:end_at]) + offset unless options[:end_at].blank?

    if options[:child_event_data].present?
      event_attributes[:child_event_data] = options[:child_event_data].map do |child_event|
        new_child_event = child_event.dup
        new_child_event[:start_at] = Time.zone.parse(child_event[:start_at]) + offset unless child_event[:start_at].blank?
        new_child_event[:end_at] = Time.zone.parse(child_event[:end_at]) + offset unless child_event[:end_at].blank?
        new_child_event
      end
    end

    event_attributes
  end

  def require_user_or_observer
    return render_unauthorized_action unless @current_user.present?
    @observee = api_find(User, params[:user_id])
    authorized_action(@observee, @current_user, :read)
  end

  def require_authorization
    @errors = {}
    user = @observee || @current_user
    codes = (params[:context_codes] || [user.asset_string])[0, 10]
    get_options(codes, user)

    # if specific context codes were requested, ensure the user can access them
    if codes && codes.length > 0
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
end
