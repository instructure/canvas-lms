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
#         }
#       }
#     }
#
class CalendarEventsApiController < ApplicationController
  include Api::V1::CalendarEvent

  before_filter :require_user, :except => %w(public_feed index)
  before_filter :get_calendar_context, :only => :create

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
    @errors = {}
    codes = (params[:context_codes] || [@current_user.asset_string])[0, 10]
    get_options(codes)

    # if specific context codes were requested, ensure the user can access them
    if codes && codes.length > 0
      selected_context_codes = Set.new(@context_codes)
      codes.each do |c|
        unless selected_context_codes.include?(c)
          render_unauthorized_action
          return
        end
      end
    else
      # otherwise, ensure there is a user provided
      unless @current_user
        redirect_to_login
        return
      end
    end

    scope = @type == :assignment ? assignment_scope : calendar_event_scope
    events = Api.paginate(scope, self, api_v1_calendar_events_url)
    ActiveRecord::Associations::Preloader.new(events, :child_events).run if @type == :event
    events = apply_assignment_overrides(events) if @type == :assignment
    mark_submitted_assignments(@current_user, events) if @type == :assignment

    if @errors.empty?
      render :json => events.map { |event| event_json(event, @current_user, session, {:excludes => params[:excludes]}) }
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
        section_events = params[:calendar_event].delete(:child_event_data)
        # handles multiple section repeast
        section_events.each do |event|
          event[:title] = title
          section_dup_options = get_duplicate_params(event)
          events += create_event_and_duplicates(section_dup_options)
        end if section_events.present?

        events += create_event_and_duplicates(dup_options) unless section_events.present?
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
        if params[:participant_id] && @event.appointment_group.grants_right?(@current_user, session, :manage)
          participant = @event.appointment_group.possible_participants.detect { |p| p.id == params[:participant_id].to_i }
        else
          participant = @event.appointment_group.participant_for(@current_user)
          participant = nil if participant && params[:participant_id] && params[:participant_id].to_i != participant.id
        end
        raise CalendarEvent::ReservationError, "invalid participant" unless participant
        reservation = @event.reserve_for(participant, @current_user, :cancel_existing => value_to_boolean(params[:cancel_existing]))
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
      params[:calendar_event].delete(:context_code)
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
        @events.concat assignment_scope.to_a
        @events = apply_assignment_overrides(@events)
        @events.concat calendar_event_scope.events_without_child_events.to_a

        # Add in any appointment groups this user can manage and someone has reserved
        appointment_codes = manageable_appointment_group_codes
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

        @events.each do |event|
          ics_event = event.to_ics(false)
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

  def get_options(codes)
    @all_events = value_to_boolean(params[:all_events])
    @undated = value_to_boolean(params[:undated])
    if !@all_events && !@undated
      validate_dates
      @start_date ||= Time.zone.now.beginning_of_day
      @end_date ||= Time.zone.now.end_of_day
      @end_date = @start_date.end_of_day if @end_date < @start_date
    end

    @type ||= params[:type] == 'assignment' ? :assignment : :event

    @context ||= @current_user

    # only get pertinent contexts if there is a user
    if @current_user
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
          @contexts.push context if context && (context.is_public || context.public_syllabus)
        end
      end

      # filter the contexts to only the requested contexts
      selected_contexts = @contexts.select { |c| codes.include?(c.asset_string) }
    else
      selected_contexts = @contexts
    end
    @context_codes = selected_contexts.map(&:asset_string)
    @section_codes = []
    if @current_user
      @section_codes = selected_contexts.inject([]) { |ary, context|
        next ary unless context.is_a?(Course)
        ary + context.sections_visible_to(@current_user).map(&:asset_string)
      }
    end

    if @type == :event && @start_date && @current_user
      # pull in reservable appointment group events, if requested
      group_codes = codes.grep(/\Aappointment_group_(\d+)\z/).map { |m| m.sub(/.*_/, '').to_i }
      if group_codes.present?
        @context_codes += AppointmentGroup.
          reservable_by(@current_user).
          intersecting(@start_date, @end_date).
          where(id: group_codes).
          map(&:asset_string)
      end
      # include manageable appointment group events for the specified contexts
      # and dates
      @context_codes += manageable_appointment_group_codes
    end
  end

  def assignment_scope
    # Fully ordering by due_at requires examining all the overrides linked and as it applies to
    # specific people, sections, etc. This applies the base assignment due_at for ordering
    # as a more sane default then natural DB order. No, it isn't perfect but much better.
    scope = assignment_context_scope.active.order_by_base_due_at.order('assignments.id ASC')

    scope = scope.send(*date_scope_and_args(:due_between_with_overrides)) unless @all_events
    scope
  end

  def assignment_context_scope
    # contexts have to be partitioned into two groups so they can be queried effectively
    contexts = @contexts.select { |c| @context_codes.include?(c.asset_string) }
    view_unpublished, other = contexts.partition { |c| c.grants_right?(@current_user, session, :view_unpublished_items) }

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
    return scope unless @current_user

    student_ids = [@current_user.id]
    courses_to_not_filter = []

    # all assignments visible to an observers students should be visible to an observer
    @current_user.observer_enrollments.shard(@current_user).each do |e|
      course_student_ids = ObserverEnrollment.observed_student_ids(e.course, @current_user)
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
       !course.feature_enabled?(:differentiated_assignments) ||
       courses_to_not_filter.include?(course.id)
      }

    # in courses with diff assignments on, only show the visible assignments
    scope = scope.filter_by_visibilities_in_given_courses(student_ids, courses_to_filter_assignments.map(&:id))
    scope
  end

  def calendar_event_scope
    scope = CalendarEvent.active.order_by_start_at.order(:id)
    if @current_user
      scope = scope.for_user_and_context_codes(@current_user, @context_codes, @section_codes)
    else
      scope = scope.for_context_codes(@context_codes)
    end

    scope = scope.send(*date_scope_and_args) unless @all_events
    scope
  end

  def search_params
    params.slice(:start_at, :end_at, :undated, :context_codes, :type)
  end

  def apply_assignment_overrides(events)
    ActiveRecord::Associations::Preloader.new(events, [:context, :assignment_overrides]).run

    events = events.inject([]) do |assignments, assignment|

      if assignment.context.user_has_been_student?(@current_user)
        assignment = assignment.overridden_for(@current_user)
        assignment.infer_all_day
        assignments << assignment
      else
        dates_list = assignment.all_dates_visible_to(@current_user)

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
          if (assignment.context.user_has_been_observer?(@current_user) && assignments.empty?) || !all_sections_overridden
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

  def manageable_appointment_group_codes
    return [] unless @current_user

    AppointmentGroup.
      manageable_by(@current_user, @context_codes).
      intersecting(@start_date, @end_date).
      map(&:asset_string)
  end

  def duplicate(options = {})
    @context ||= @current_user

    if @current_user
      get_all_pertinent_contexts(include_groups: true)
    end

    options[:iterator] ||= 0
    params = set_duplicate_params(options)
    event = @context.calendar_events.build(params[:calendar_event])
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
        count:     duplicate_data.fetch(:count, 0).to_i,
        interval:  duplicate_data.fetch(:interval, 1).to_i,
        add_count: value_to_boolean(duplicate_data[:append_iterator]),
        frequency: duplicate_data.fetch(:frequency, "weekly")
    }
  end

  def set_duplicate_params(options = {})
    options[:iterator] ||= 0
    offset_interval = options[:interval] * options[:iterator]
    offset = if options[:frequency] == "monthly"
               offset_interval.months
             elsif options[:frequency] == "daily"
               offset_interval.days
             else
               offset_interval.weeks
             end

    params[:calendar_event][:title] = "#{options[:title]} #{options[:iterator] + 1}" if options[:add_count]
    params[:calendar_event][:start_at] = Time.iso8601(options[:start_at]) + offset unless options[:start_at].blank?
    params[:calendar_event][:end_at] = Time.iso8601(options[:end_at]) + offset unless options[:end_at].blank?
    params
  end
end