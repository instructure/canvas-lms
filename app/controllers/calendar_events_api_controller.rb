#
# Copyright (C) 2011 Instructure, Inc.
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

# @API Calendar Events
#
# API for creating, accessing and updating calendar events.
#
# @object Calendar Event
#     {
#       // The ID of the calendar event
#       id: 234,
#
#       // The title of the calendar event
#       title: "Paintball Fight!",
#
#       // The start timestamp of the event
#       start_at: "2012-07-19T15:00:00-06:00",
#
#       // The end timestamp of the event
#       end_at: "2012-07-19T16:00:00-06:00",
#
#       // The HTML description of the event
#       description: "<b>It's that time again!</b>",
#
#       // The location name of the event
#       location_name: "Greendale Community College",
#
#       // The address where the event is taking place
#       location_address: "Greendale, Colorado",
#
#       // the context code of the calendar this event belongs to (course, user
#       // or group)
#       context_code: "course_123",
#
#       // if specified, it indicates which calendar this event should be
#       // displayed on. for example, a section-level event would have the
#       // course's context code here, while the section's context code would
#       // be returned above)
#       effective_context_code: null,
#
#       // Current state of the event ("active", "locked" or "deleted")
#       // "locked" indicates that start_at/end_at cannot be changed (though
#       // the event could be deleted). Normally only reservations or time
#       // slots with reservations are locked (see the Appointment Groups API)
#       workflow_state: "active",
#
#       // Whether this event should be displayed on the calendar. Only true
#       // for course-level events with section-level child events.
#       hidden: false,
#
#       // Normally null. If this is a reservation (see the Appointment Groups
#       // API), the id will indicate the time slot it is for. If this is a
#       // section-level event, this will be the course-level parent event.
#       parent_event_id: null,
#
#       // The number of child_events. See child_events (and parent_event_id)
#       child_events_count: 0,
#
#       // Included by default, but may be excluded (see include[] option).
#       // If this is a time slot (see the Appointment Groups API) this will
#       // be a list of any reservations. If this is a course-level event,
#       // this will be a list of section-level events (if any)
#       child_events: [],
#
#       // URL for this calendar event (to update, delete, etc.)
#       url: "https://example.com/api/v1/calendar_events/234",
#
#       // The date of this event
#       all_day_date: "2012-07-19",
#
#       // Boolean indicating whether this is an all-day event (midnight to
#       // midnight)
#       all_day: false,
#
#       // When the calendar event was created
#       created_at: "2012-07-12T10:55:20-06:00",
#
#       // When the calendar event was last updated
#       updated_at: "2012-07-12T10:55:20-06:00",
#
#
#       ///////////////////////////////////////////////////////////////////////
#       // Various Appointment-Group-related fields                          //
#       //                                                                   //
#       // These fields are only pertinent to time slots (appointments) and  //
#       // reservations of those time slots. See the Appointment Groups API  //
#       ///////////////////////////////////////////////////////////////////////
#
#       // The id of the appointment group
#       appointment_group_id: null,
#
#       // The API URL of the appointment group
#       appointment_group_url: null,
#
#       // If the event is a reservation, this a boolean indicating whether it
#       // is the current user's reservation, or someone else's
#       own_reservation: null,
#
#       // If the event is a time slot, the API URL for reserving it 
#       reserve_url: null,
#
#       // If the event is a time slot, a boolean indicating whether the user
#       // has already made a reservation for it 
#       reserved: null,
#
#       // If the event is a time slot, this is the participant limit
#       participants_per_appointment: null,
#
#       // If the event is a time slot and it has a participant limit, an
#       // integer indicating how many slots are available
#       available_slots: null,
#
#       // If the event is a user-level reservation, this will contain the user
#       // participant JSON (refer to the Users API).
#       user: null,
#
#       // If the event is a group-level reservation, this will contain the
#       // group participant JSON (refer to the Groups API).
#       group: null
#     }
#
# @object Assignment Event
#     {
#       // A synthetic ID for the assignment
#       id: "assignment_987",
#
#       // The title of the assignment
#       title: "Essay",
#
#       // The due_at timestamp of the assignment
#       start_at: "2012-07-19T23:59:00-06:00",
#
#       // The due_at timestamp of the assignment
#       end_at: "2012-07-19T23:59:00-06:00",
#
#       // The HTML description of the assignment
#       description: "<b>Write an essay. Whatever you want.</b>",
#
#       // the context code of the (course) calendar this assignment belongs to
#       context_code: "course_123",
#
#       // Current state of the assignment ("available", "published" or
#       // "deleted")
#       workflow_state: "published",
#
#       // URL for this assignment (note that updating/deleting should be done
#       // via the Assignments API)
#       url: "https://example.com/api/v1/calendar_events/assignment_987",
#
#       // The due date of this assignment
#       all_day_date: "2012-07-19",
#
#       // Boolean indicating whether this is an all-day event (e.g. assignment
#       // due at midnight)
#       all_day: true,
#
#       // When the assignment was created
#       created_at: "2012-07-12T10:55:20-06:00",
#
#       // When the assignment was last updated
#       updated_at: "2012-07-12T10:55:20-06:00",
#
#       // The full assignment JSON data (See the Assignments API)
#       assigmment: { id: 987, ... }
#     }

class CalendarEventsApiController < ApplicationController
  include Api::V1::CalendarEvent

  before_filter :require_user
  before_filter :get_calendar_context, :only => :create
  before_filter :get_options, :only => :index

  # @API List calendar events
  #
  # Retrieve the list of calendar events or assignments for the current user
  #
  # @argument type [Optional, "event"|"assignment"] Defaults to "event"
  # @argument start_date [Optional] Only return events since the start_date
  #   (inclusive)
  # @argument end_date [Optional] Only return events before the end_date
  #   (inclusive)
  # @argument undated [Optional] Boolean, defaults to false (dated events only).
  #   If true, only return undated events
  # @argument context_codes[] [optional] List of context codes of courses/groups/users
  #   (e.g. course_123) whose events you want to see. If not specified, defaults
  #   to the current user (i.e personal calendar, no course/group events).
  #   Limited to 10 context codes, additional ones are ignored
  def index
    scope = if @type == :assignment
      Assignment.active.
        for_context_codes(@context_codes).
        send(*date_scope_and_args(:due_between))
    else
      CalendarEvent.active.
        for_user_and_context_codes(@current_user, @context_codes, @section_codes).
        send(*date_scope_and_args)
    end

    events = Api.paginate(scope.order('id'), self, api_v1_calendar_events_path(search_params))
    CalendarEvent.send(:preload_associations, events, :child_events) if @type == :event
    render :json => events.map{ |event| event_json(event, @current_user, session) }
  end

  # @API Create a calendar event
  #
  # Create and return a new calendar event
  #
  # @argument calendar_event[context_code] [Required] Context code of the course/group/user whose calendar this event should be added to
  # @argument calendar_event[title] [Optional] Short title for the calendar event
  # @argument calendar_event[description] [Optional] Longer HTML description of the event
  # @argument calendar_event[start_at] [Optional] Start date/time of the event
  # @argument calendar_event[end_at] [Optional] End date/time of the event
  # @argument calendar_event[location_name] [Optional] Location name of the event
  # @argument calendar_event[location_address] [Optional] Location address
  # @argument calendar_event[time_zone_edited] [Optional] Time zone of the user editing the event. Allowed time zones are listed in {http://rubydoc.info/docs/rails/2.3.8/ActiveSupport/TimeZone The Ruby on Rails documentation}.
  # @argument calendar_event[child_event_data][X][start_at] [Optional] Section-level start time(s) if this is a course event. X can be any identifier, provided that it is consistent across the start_at, end_at and context_code
  # @argument calendar_event[child_event_data][X][end_at] [Optional] Section-level end time(s) if this is a course event.
  # @argument calendar_event[child_event_data][X][context_code] [Optional] Context code(s) corresponding to the section-level start and end time(s).
  #
  # @example_request
  #
  #   curl 'http://<canvas>/api/v1/calendar_events.json' \ 
  #        -X POST \ 
  #        -F 'calendar_event[context_code]=course_123' \ 
  #        -F 'calendar_event[title]=Paintball Fight!' \ 
  #        -F 'calendar_event[start_at]=2012-07-19T21:00:00Z' \ 
  #        -F 'calendar_event[end_at]=2012-07-19T22:00:00Z' \ 
  #        -H "Authorization: Bearer <token>"
  def create
    @event = @context.calendar_events.build(params[:calendar_event])
    if authorized_action(@event, @current_user, :create)
      @event.validate_context! if @context.is_a?(AppointmentGroup)
      @event.updating_user = @current_user
      if @event.save
        render :json => event_json(@event, @current_user, session), :status => :created
      else
        render :json => @event.errors.to_json, :status => :bad_request
      end
    end
  end

  # @API Get a single calendar event or assignment
  #
  # Returns information for a single event or assignment
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
  # @argument participant_id [Optional]. User or group id for whom you are
  #   making the reservation (depends on the participant type). Defaults to the
  #   current user (or user's candidate group).
  # @argument cancel_existing [Optional]. Defaults to false. If true, cancel
  #   any previous reservation(s) for this participant and appointment group.
  #
  # @example_request
  #
  #   curl 'http://<canvas>/api/v1/calendar_events/345/reservations.json' \ 
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
            :reservations => reservations.map{ |r| event_json(r, @current_user, session) }
          }],
          :status => :bad_request
      end
    end
  end

  # @API Update a calendar event
  #
  # Update and return a calendar event
  #
  # @argument calendar_event[title] [Optional] Short title for the calendar event
  # @argument calendar_event[description] [Optional] Longer HTML description of the event
  # @argument calendar_event[start_at] [Optional] Start date/time of the event
  # @argument calendar_event[end_at] [Optional] End date/time of the event
  # @argument calendar_event[location_name] [Optional] Location name of the event
  # @argument calendar_event[location_address] [Optional] Location address
  # @argument calendar_event[time_zone_edited] [Optional] Time zone of the user editing the event. Allowed time zones are listed in {http://rubydoc.info/docs/rails/2.3.8/ActiveSupport/TimeZone The Ruby on Rails documentation}.
  # @argument calendar_event[child_event_data][X][start_at] [Optional] Section-level start time(s) if this is a course event. X can be any identifier, provided that it is consistent across the start_at, end_at and context_code. Note that if any child_event_data is specified, it will replace any existing child events.
  # @argument calendar_event[child_event_data][X][end_at] [Optional] Section-level end time(s) if this is a course event.
  # @argument calendar_event[child_event_data][X][context_code] [Optional] Context code(s) corresponding to the section-level start and end time(s).
  # @argument calendar_event[remove_child_events] [Optional] Boolean, indicates that all child events (i.e. section-level events) should be removed.
  # @argument calendar_event[participants_per_appointment] [Optional] Maximum number of participants that may sign up for this time slot. Ignored for regular calendar events or reservations.
  #
  # @example_request
  #
  #   curl 'http://<canvas>/api/v1/calendar_events/234.json' \ 
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
      if @event.update_attributes(params[:calendar_event])
        render :json => event_json(@event, @current_user, session)
      else
        render :json => @event.errors.to_json, :status => :bad_request
      end
    end
  end

  # @API Delete a calendar event
  #
  # Delete an event from the calendar and return the deleted event
  #
  # @argument cancel_reason [Optional] Reason for deleting/canceling the event.
  #
  # @example_request
  #
  #   curl 'http://<canvas>/api/v1/calendar_events/234.json' \ 
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
        render :json => @event.errors.to_json, :status => :bad_request
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

  def get_options
    unless value_to_boolean(params[:undated])
      today = ActiveSupport::TimeWithZone.new(Time.now, Time.zone).to_date
      @start_date = params[:start_date] && (Date.parse(params[:start_date]) rescue nil) || today.to_date
      @end_date = params[:end_date] && (Date.parse(params[:end_date]) rescue nil) || today.to_date
      @end_date = @start_date if @end_date < @start_date
      @end_date += 1
    end

    @type = params[:type] == 'assignment' ? :assignment : :event

    @context = @current_user
    codes = (params[:context_codes] || [])[0, 10]
    # refactor opportunity: get_all_pertinent_contexts expects the list of
    # unenrolled contexts to be in the include_contexts parameter, rather than
    # a function parameter
    params[:include_contexts] = codes.join(",")

    get_all_pertinent_contexts(true)

    selected_contexts = @contexts.select{ |c| codes.include?(c.asset_string) }
    @context_codes = selected_contexts.map(&:asset_string)
    @section_codes = selected_contexts.inject([]){ |ary, context|
      next ary unless context.is_a?(Course)
      ary + context.sections_visible_to(@current_user).map(&:asset_string)
    }

    if @type == :event && @start_date
      # pull in reservable appointment group events, if requested
      group_codes = codes.grep(/\Aappointment_group_(\d+)\z/).map{ |m| m.sub(/.*_/, '').to_i }
      if group_codes.present?
        @context_codes += AppointmentGroup.
                            reservable_by(@current_user).
                            intersecting(@start_date, @end_date).
                            find_all_by_id(group_codes).
                            map(&:asset_string)
      end
      # include manageable appointment group events for the specified contexts
      # and dates
      @context_codes += AppointmentGroup.
                          manageable_by(@current_user, @context_codes).
                          intersecting(@start_date, @end_date).
                          map(&:asset_string)
    end
  end

  def search_params
    params.slice(:start_at, :end_at, :undated, :context_codes, :type)
  end
end
