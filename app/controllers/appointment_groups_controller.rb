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

# @API Appointment Groups
#
# API for creating, accessing and updating appointment groups. Appointment groups
# provide a way of creating a bundle of time slots that users can sign up for
# (e.g. "Office Hours" or "Meet with professor about Final Project"). Both time
# slots and reservations of time slots are stored as Calendar Events.
#
# @model Appointment
#     {
#       "id": "Appointment",
#       "description": "Date and time for an appointment",
#       "properties": {
#         "id": {
#           "description": "The appointment identifier.",
#           "example": 987,
#           "type": "integer"
#         },
#         "start_at": {
#           "description": "Start time for the appointment",
#           "example": "2012-07-20T15:00:00-06:00",
#           "type": "datetime"
#         },
#         "end_at": {
#           "description": "End time for the appointment",
#           "example": "2012-07-20T15:00:00-06:00",
#           "type": "datetime"
#         }
#       }
#     }
#
# @model AppointmentGroup
#     {
#       "id": "AppointmentGroup",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "The ID of the appointment group",
#           "example": 543,
#           "type": "integer"
#         },
#         "title": {
#           "description": "The title of the appointment group",
#           "example": "Final Presentation",
#           "type": "string"
#         },
#         "start_at": {
#           "description": "The start of the first time slot in the appointment group",
#           "example": "2012-07-20T15:00:00-06:00",
#           "type": "datetime"
#         },
#         "end_at": {
#           "description": "The end of the last time slot in the appointment group",
#           "example": "2012-07-20T17:00:00-06:00",
#           "type": "datetime"
#         },
#         "description": {
#           "description": "The text description of the appointment group",
#           "example": "Es muy importante",
#           "type": "string"
#         },
#         "location_name": {
#           "description": "The location name of the appointment group",
#           "example": "El Tigre Chino's office",
#           "type": "string"
#         },
#         "location_address": {
#           "description": "The address of the appointment group's location",
#           "example": "Room 234",
#           "type": "string"
#         },
#         "participant_count": {
#           "description": "The number of participant who have reserved slots (see include[] argument)",
#           "example": 2,
#           "type": "integer"
#         },
#         "reserved_times": {
#           "description": "The start and end times of slots reserved by the current user as well as the id of the calendar event for the reservation (see include[] argument)",
#           "example": [{"id": 987, "start_at": "2012-07-20T15:00:00-06:00", "end_at": "2012-07-20T15:00:00-06:00"}],
#           "type": "array",
#           "items": {"$ref": "Appointment"}
#         },
#         "context_codes": {
#           "description": "The context codes (i.e. courses) this appointment group belongs to. Only people in these courses will be eligible to sign up.",
#           "example": ["course_123"],
#           "type": "array",
#           "items": {"type": "string"}
#         },
#         "sub_context_codes": {
#           "description": "The sub-context codes (i.e. course sections and group categories) this appointment group is restricted to",
#           "example": ["course_section_234"],
#           "type": "array",
#           "items": {"type": "integer"}
#         },
#         "workflow_state": {
#           "description": "Current state of the appointment group ('pending', 'active' or 'deleted'). 'pending' indicates that it has not been published yet and is invisible to participants.",
#           "example": "active",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "pending",
#               "active",
#               "deleted"
#             ]
#           }
#         },
#         "requiring_action": {
#           "description": "Boolean indicating whether the current user needs to sign up for this appointment group (i.e. it's reservable and the min_appointments_per_participant limit has not been met by this user).",
#           "example": true,
#           "type": "boolean"
#         },
#         "appointments_count": {
#           "description": "Number of time slots in this appointment group",
#           "example": 2,
#           "type": "integer"
#         },
#         "appointments": {
#           "description": "Calendar Events representing the time slots (see include[] argument) Refer to the Calendar Events API for more information",
#           "example": [],
#           "type": "array",
#           "items": {"$ref": "CalendarEvent"}
#         },
#         "new_appointments": {
#           "description": "Newly created time slots (same format as appointments above). Only returned in Create/Update responses where new time slots have been added",
#           "example": [],
#           "type": "array",
#           "items": {"$ref": "CalendarEvent"}
#         },
#         "max_appointments_per_participant": {
#           "description": "Maximum number of time slots a user may register for, or null if no limit",
#           "example": 1,
#           "type": "integer"
#         },
#         "min_appointments_per_participant": {
#           "description": "Minimum number of time slots a user must register for. If not set, users do not need to sign up for any time slots",
#           "example": 1,
#           "type": "integer"
#         },
#         "participants_per_appointment": {
#           "description": "Maximum number of participants that may register for each time slot, or null if no limit",
#           "example": 1,
#           "type": "integer"
#         },
#         "participant_visibility": {
#           "description": "'private' means participants cannot see who has signed up for a particular time slot, 'protected' means that they can",
#           "example": "private",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "private",
#               "protected"
#             ]
#           }
#         },
#         "participant_type": {
#           "description": "Indicates how participants sign up for the appointment group, either as individuals ('User') or in student groups ('Group'). Related to sub_context_codes (i.e. 'Group' signups always have a single group category)",
#           "example": "User",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "User",
#               "Group"
#             ]
#           }
#         },
#         "url": {
#           "description": "URL for this appointment group (to update, delete, etc.)",
#           "example": "https://example.com/api/v1/appointment_groups/543",
#           "type": "string"
#         },
#         "html_url": {
#           "description": "URL for a user to view this appointment group",
#           "example": "http://example.com/appointment_groups/1",
#           "type": "string"
#         },
#         "created_at": {
#           "description": "When the appointment group was created",
#           "example": "2012-07-13T10:55:20-06:00",
#           "type": "datetime"
#         },
#         "updated_at": {
#           "description": "When the appointment group was last updated",
#           "example": "2012-07-13T10:55:20-06:00",
#           "type": "datetime"
#         }
#       }
#     }
#
class AppointmentGroupsController < ApplicationController
  include Api::V1::CalendarEvent

  before_filter :require_user
  before_filter :get_appointment_group, :only => [:show, :update, :destroy, :users, :groups, :edit]

  def calendar_fragment(opts)
    opts.to_json.unpack('H*')
  end
  private :calendar_fragment

  # @API List appointment groups
  #
  # Retrieve the list of appointment groups that can be reserved or managed by
  # the current user.
  #
  # @argument scope [String, "reservable"|"manageable"]
  #   Defaults to "reservable"
  #
  # @argument context_codes[] [String]
  #   Array of context codes used to limit returned results.
  #
  # @argument include_past_appointments [Boolean]
  #   Defaults to false. If true, includes past appointment groups
  #
  # @argument include[] ["appointments"|"child_events"|"participant_count"|"reserved_times"|"all_context_codes"]
  #   Array of additional information to include.
  #
  #   "appointments":: calendar event time slots for this appointment group
  #   "child_events":: reservations of those time slots
  #   "participant_count":: number of reservations
  #   "reserved_times":: the event id, start time and end time of reservations
  #                      the current user has made)
  #   "all_context_codes":: all context codes associated with this appointment group
  def index
    return web_index unless request.format == :json

    contexts = params[:context_codes] if params.include?(:context_codes)

    if params[:scope] == 'manageable'
      scope = AppointmentGroup.manageable_by(@current_user, contexts)
      scope = scope.current_or_undated unless value_to_boolean(params[:include_past_appointments])
    else
      scope = AppointmentGroup.reservable_by(@current_user, contexts)
      scope = scope.current unless value_to_boolean(params[:include_past_appointments])
    end
    groups = Api.paginate(
      scope.order('id'),
      self,
      api_v1_appointment_groups_url(:scope => params[:scope])
    )
    if params[:include]
      ActiveRecord::Associations::Preloader.new.preload(groups,
                            [{:appointments =>
                               [:parent_event,
                                {:context =>
                                  [{:appointment_group_contexts => :context},
                                   :appointment_group_sub_contexts]},
                                {:child_events =>
                                  [:parent_event,
                                   :context,
                                   {:child_events =>
                                     [:parent_event,
                                      :context]}]}]},
                             {:appointment_group_contexts => :context},
                             :appointment_group_sub_contexts])
    end
    render :json => groups.map{ |group| appointment_group_json(group, @current_user, session, :include => params[:include]) }
  end

  # @API Create an appointment group
  #
  # Create and return a new appointment group. If new_appointments are
  # specified, the response will return a new_appointments array (same format
  # as appointments array, see "List appointment groups" action)
  #
  # @argument appointment_group[context_codes][] [Required, String]
  #   Array of context codes (courses, e.g. course_1) this group should be
  #   linked to (1 or more). Users in the course(s) with appropriate permissions
  #   will be able to sign up for this appointment group.
  #
  # @argument appointment_group[sub_context_codes][] [String]
  #   Array of sub context codes (course sections or a single group category)
  #   this group should be linked to. Used to limit the appointment group to
  #   particular sections. If a group category is specified, students will sign
  #   up in groups and the participant_type will be "Group" instead of "User".
  #
  # @argument appointment_group[title] [Required, String]
  #   Short title for the appointment group.
  #
  # @argument appointment_group[description] [String]
  #   Longer text description of the appointment group.
  #
  # @argument appointment_group[location_name] [String]
  #   Location name of the appointment group.
  #
  # @argument appointment_group[location_address] [String]
  #   Location address.
  #
  # @argument appointment_group[publish] [Boolean]
  #   Indicates whether this appointment group should be published (i.e. made
  #   available for signup). Once published, an appointment group cannot be
  #   unpublished. Defaults to false.
  #
  # @argument appointment_group[participants_per_appointment] [Integer]
  #   Maximum number of participants that may register for each time slot.
  #   Defaults to null (no limit).
  #
  # @argument appointment_group[min_appointments_per_participant] [Integer]
  #   Minimum number of time slots a user must register for. If not set, users
  #   do not need to sign up for any time slots.
  #
  # @argument appointment_group[max_appointments_per_participant] [Integer]
  #   Maximum number of time slots a user may register for.
  #
  # @argument appointment_group[new_appointments][X][]
  #   Nested array of start time/end time pairs indicating time slots for this
  #   appointment group. Refer to the example request.
  #
  # @argument appointment_group[participant_visibility] ["private"|"protected"]
  #   "private":: participants cannot see who has signed up for a particular
  #               time slot
  #   "protected":: participants can see who has signed up.  Defaults to
  #                 "private".
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/appointment_groups.json' \
  #        -X POST \
  #        -F 'appointment_group[context_codes][]=course_123' \
  #        -F 'appointment_group[sub_context_codes][]=course_section_234' \
  #        -F 'appointment_group[title]=Final Presentation' \
  #        -F 'appointment_group[participants_per_appointment]=1' \
  #        -F 'appointment_group[min_appointments_per_participant]=1' \
  #        -F 'appointment_group[max_appointments_per_participant]=1' \
  #        -F 'appointment_group[new_appointments][0][]=2012-07-19T21:00:00Z' \
  #        -F 'appointment_group[new_appointments][0][]=2012-07-19T22:00:00Z' \
  #        -F 'appointment_group[new_appointments][1][]=2012-07-19T22:00:00Z' \
  #        -F 'appointment_group[new_appointments][1][]=2012-07-19T23:00:00Z' \
  #        -H "Authorization: Bearer <token>"
  def create
    contexts = get_contexts
    raise ActiveRecord::RecordNotFound unless contexts.present?

    publish = value_to_boolean(params[:appointment_group].delete(:publish))
    @group = AppointmentGroup.new(appointment_group_params.merge(:contexts => contexts))
    @group.update_contexts_and_sub_contexts
    if authorized_action(@group, @current_user, :manage)
      if @group.save
        @group.publish! if publish
        render :json => appointment_group_json(@group, @current_user, session), :status => :created
      else
        render :json => @group.errors, :status => :bad_request
      end
    end
  end

  # @API Get a single appointment group
  #
  # Returns information for a single appointment group
  #
  # @argument include[] ["child_events"|"appointments"|"all_context_codes"]
  #   Array of additional information to include. See include[] argument of
  #   "List appointment groups" action.
  #
  #   "child_events":: reservations of time slots time slots
  #   "appointments":: will always be returned
  #   "all_context_codes":: all context codes associated with this appointment group
  def show
    if authorized_action(@group, @current_user, :read)
      return web_show unless request.format == :json

      render :json => appointment_group_json(@group, @current_user, session,
                                             :include => ((params[:include] || []) | ['appointments']),
                                             :include_past_appointments => @group.grants_right?(@current_user, :manage))
    end
  end

  # Shows the edit page for an assignment group
  def edit
    if request.format == :html
      if authorized_action(@group, @current_user, :update)
        @page_title = t('Edit %{title}', {title: @group.title})
        js_env({
          :APPOINTMENT_GROUP_ID => @group.id,
          :CALENDAR => {
            MAX_GROUP_CONVERSATION_SIZE: 100,
          }
        })
        js_bundle :calendar_appointment_group_edit
        css_bundle :calendar_appointment_group_edit
        render :text => "".html_safe, :layout => true
      end
    end
  end

  # @API Update an appointment group
  #
  # Update and return an appointment group. If new_appointments are specified,
  # the response will return a new_appointments array (same format as
  # appointments array, see "List appointment groups" action).
  #
  # @argument appointment_group[context_codes][] [Required, String]
  #   Array of context codes (courses, e.g. course_1) this group should be
  #   linked to (1 or more). Users in the course(s) with appropriate permissions
  #   will be able to sign up for this appointment group.
  #
  # @argument appointment_group[sub_context_codes][] [String]
  #   Array of sub context codes (course sections or a single group category)
  #   this group should be linked to. Used to limit the appointment group to
  #   particular sections. If a group category is specified, students will sign
  #   up in groups and the participant_type will be "Group" instead of "User".
  #
  # @argument appointment_group[title] [String]
  #   Short title for the appointment group.
  #
  # @argument appointment_group[description] [String]
  #   Longer text description of the appointment group.
  #
  # @argument appointment_group[location_name] [String]
  #   Location name of the appointment group.
  #
  # @argument appointment_group[location_address] [String]
  #   Location address.
  #
  # @argument appointment_group[publish] [Boolean]
  #   Indicates whether this appointment group should be published (i.e. made
  #   available for signup). Once published, an appointment group cannot be
  #   unpublished. Defaults to false.
  #
  # @argument appointment_group[participants_per_appointment] [Integer]
  #   Maximum number of participants that may register for each time slot.
  #   Defaults to null (no limit).
  #
  # @argument appointment_group[min_appointments_per_participant] [Integer]
  #   Minimum number of time slots a user must register for. If not set, users
  #   do not need to sign up for any time slots.
  #
  # @argument appointment_group[max_appointments_per_participant] [Integer]
  #   Maximum number of time slots a user may register for.
  #
  # @argument appointment_group[new_appointments][X][]
  #   Nested array of start time/end time pairs indicating time slots for this
  #   appointment group. Refer to the example request.
  #
  # @argument appointment_group[participant_visibility] ["private"|"protected"]
  #   "private":: participants cannot see who has signed up for a particular
  #               time slot
  #   "protected":: participants can see who has signed up. Defaults to "private".
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/appointment_groups/543.json' \
  #        -X PUT \
  #        -F 'appointment_group[publish]=1' \
  #        -H "Authorization: Bearer <token>"
  def update
    contexts = get_contexts
    @group.contexts = contexts if contexts
    if authorized_action(@group, @current_user, :update)
      publish = params[:appointment_group].delete(:publish) == "1"
      if (publish && params[:appointment_group].blank?) || @group.update_attributes(appointment_group_params)
        @group.publish! if publish
        render :json => appointment_group_json(@group, @current_user, session)
      else
        render :json => @group.errors, :status => :bad_request
      end
    end
  end

  # @API Delete an appointment group
  #
  # Delete an appointment group (and associated time slots and reservations)
  # and return the deleted group
  #
  # @argument cancel_reason [String]
  #   Reason for deleting/canceling the appointment group.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/appointment_groups/543.json' \
  #        -X DELETE \
  #        -F 'cancel_reason=El Tigre Chino got fired' \
  #        -H "Authorization: Bearer <token>"
  def destroy
    if authorized_action(@group, @current_user, :delete)
      @group.cancel_reason = params[:cancel_reason]
      if @group.destroy
        render :json => appointment_group_json(@group, @current_user, session)
      else
        render :json => @group.errors, :status => :bad_request
      end
    end
  end

  # @API List user participants
  #
  # List users that are (or may be) participating in this appointment group.
  # Refer to the Users API for the response fields. Returns no results for
  # appointment groups with the "Group" participant_type.
  #
  # @argument registration_status ["all"|"registered"|"registered"]
  #   Limits results to the a given participation status, defaults to "all"
  def users
    participants('User'){ |u| user_json(u, @current_user, session) }
  end

  # @API List student group participants
  #
  # List student groups that are (or may be) participating in this appointment
  # group. Refer to the Groups API for the response fields. Returns no results
  # for appointment groups with the "User" participant_type.
  #
  # @argument registration_status ["all"|"registered"|"registered"]
  #   Limits results to the a given participation status, defaults to "all"
  def groups
    participants('Group'){ |g| group_json(g, @current_user, session) }
  end

  # @API Get next appointment
  #
  # Return the next appointment available to sign up for. The appointment
  # is returned in a one-element array. If no future appointments are
  # available, an empty array is returned.
  #
  # @argument appointment_group_ids[] [String]
  #   List of ids of appointment groups to search.
  #
  # @returns [CalendarEvent]
  def next_appointment
    ag_scope = AppointmentGroup.current.reservable_by(@current_user)
    ids = Array(params[:appointment_group_ids])
    ag_scope = ag_scope.where(id: ids) if ids.any?
    # FIXME this could be a lot faster if we didn't look at eligibility to sign up.
    # since the UI only cares about the date to jump to, it might not make a difference in many cases
    events = ag_scope.preload(:appointments => :child_events).to_a.map do |ag|
      ag.appointments.detect do |appointment|
        appointment.child_events_for(@current_user).empty? &&
          (appointment.participants_per_appointment.nil? ||
           appointment.child_events.count < appointment.participants_per_appointment)
      end
    end.compact
    render :json => events.sort_by(&:start_at)[0..0].map { |event|
      calendar_event_json(event, @current_user, session)
    }
  end

  protected

  def participants(type, &formatter)
    if authorized_action(@group, @current_user, :read)
      return render :json => [] unless @group.participant_type == type
      render :json => Api.paginate(
        @group.possible_participants(registration_status: params[:registration_status]),
        self,
        send("api_v1_appointment_group_#{params[:action]}_url", @group)
      ).map(&formatter)
    end
  end

  def get_contexts
    if params[:appointment_group] && params[:appointment_group][:context_codes]
      context_codes = params[:appointment_group].delete(:context_codes)
      contexts = context_codes.map do |code|
        Context.find_by_asset_string(code)
      end
    end
    contexts
  end

  def get_appointment_group
    @group = AppointmentGroup.find(params[:id].to_i)
    @context = @group.contexts_for_user(@current_user).first # FIXME?
  end

  def appointment_group_params
    strong_params.require(:appointment_group).permit(:title, :description, :location_name, :location_address, :participants_per_appointment,
      :min_appointments_per_participant, :max_appointments_per_participant, :participant_visibility, :cancel_reason,
      :sub_context_codes => [], :new_appointments => strong_anything)
  end

  def web_index
    anchor = if @domain_root_account.feature_enabled?(:better_scheduler)
      # start with the first reservable appointment group
      group = AppointmentGroup.reservable_by(@current_user, params[:context_codes]).current.order(:start_at).first
      calendar_fragment :view_name => :agenda, :view_start => group && group.start_at.strftime('%Y-%m-%d')
    else
      calendar_fragment :view_name => :scheduler
    end
    return redirect_to calendar2_url(:anchor => anchor)
  end

  def web_show
    anchor = if @domain_root_account.feature_enabled?(:better_scheduler)
      args = {}
      if params[:find_appointment]
        # start at the appointment group; enter find-appointment mode for a relevant course
        args[:view_start] = @group.start_at.strftime('%Y-%m-%d')
        course_id = @group.appointment_group_contexts.where(context_type: 'Course', context_id: @current_user.student_enrollments.pluck(:course_id)).pluck(:context_id).first
        args[:find_appointment] = "course_#{course_id}"
      else
        # start at the appointment event, or the group start if no event is given
        event = params[:event_id] && CalendarEvent.find_by_id(params[:event_id])
        event = nil unless event && event.grants_right?(@current_user, :read)
        args[:view_start] = (event || @group).start_at.strftime('%Y-%m-%d')
      end
      calendar_fragment({ :view_name => :agenda }.merge(args))
    else
      calendar_fragment :view_name => :scheduler, :appointment_group_id => @group.id
    end
    return redirect_to calendar2_url(:anchor => anchor)
  end
end
