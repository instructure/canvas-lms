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
# @object Appointment Group
#     {
#       // The ID of the appointment group
#       id: 543,
#
#       // The title of the appointment group
#       title: "Final Presentation",
#
#       // The start of the first time slot in the appointment group
#       start_at: "2012-07-20T15:00:00-06:00",
#
#       // The end of the last time slot in the appointment group
#       end_at: "2012-07-20T17:00:00-06:00",
#
#       // The text description of the appointment group
#       description: "Es muy importante",
#
#       // The location name of the appointment group
#       location_name: "El Tigre Chino's office",
#
#       // The address of the appointment group's location
#       location_address: "Room 234",
#
#       // The context codes (i.e. courses) this appointment group belongs to.
#       // Only people in these courses will be eligible to sign up.
#       context_codes: ["course_123"],
#
#       // The sub-context codes (i.e. course sections and group categories)
#       // this appointment group is restricted to
#       sub_context_codes: ["course_section_234"],
#
#       // Current state of the appointment group ("pending", "active" or
#       // "deleted"). "pending" indicates that it has not been published yet
#       // and is invisible to participants.
#       workflow_state: "active",
#
#       // Boolean indicating whether the current user needs to sign up for
#       // this appointment group (i.e. it's reservable and the
#       // min_appointments_per_participant limit has not been met by this
#       // user).
#       requiring_action: true,
#
#       // Number of time slots in this appointment group
#       appointments_count: 2,
#
#       // Calendar Events representing the time slots (see include[] argument)
#       // Refer to the Calendar Events API for more information
#       appointments: [ ... ],
#
#       // Newly created time slots (same format as appointments above). Only
#       // returned in Create/Update responses where new time slots have been
#       // added
#       new_appointments: [ ... ],
#
#       // Maximum number of time slots a user may register for, or null if no
#       // limit
#       max_appointments_per_participant: 1,
#
#       // Minimum number of time slots a user must register for. If not set,
#       // users do not need to sign up for any time slots
#       min_appointments_per_participant: 1,
#
#       // Maximum number of participants that may register for each time slot,
#       // or null if no limit
#       participants_per_appointment: 1,
#
#       // "private" means participants cannot see who has signed up for a
#       // particular time slot, "protected" means that they can
#       participant_visibility: "private",
#
#       // Indicates how participants sign up for the appointment group, either
#       // as individuals ("User") or in student groups ("Group"). Related to 
#       // sub_context_codes (i.e. "Group" signups always have a single group
#       // category)
#       participant_type: "User",
#
#       // URL for this appointment group (to update, delete, etc.)
#       url: "https://example.com/api/v1/appointment_groups/543",
#
#       // When the appointment group was created
#       created_at: "2012-07-13T10:55:20-06:00",
#
#       // When the appointment group was last updated
#       updated_at: "2012-07-13T10:55:20-06:00"
#     }

class AppointmentGroupsController < ApplicationController
  include Api::V1::CalendarEvent

  before_filter :require_user
  before_filter :get_appointment_group, :only => [:show, :update, :destroy, :users, :groups]

  def calendar_fragment(opts)
    opts.to_json.unpack('H*')
  end
  private :calendar_fragment

  # @API List appointment groups
  #
  # Retrieve the list of appointment groups that can be reserved or managed by
  # the current user.
  #
  # @argument scope [Optional, "reservable"|"manageable"] Defaults to "reservable"
  # @argument include_past_appointments [Optional] Boolean, defaults to false.
  #   If true, includes past appointment groups
  # @argument include[] [Optional] Array of additional information to include.
  #   Allowable values include "appointments" (i.e. calendar event time slots
  #   for this appointment group) and "child_events" (i.e. reservations of those
  #   time slots)
  def index
    unless request.format == :json
      anchor = calendar_fragment :view_name => :scheduler
      return redirect_to calendar2_url(:anchor => anchor)
    end

    if params[:scope] == 'manageable'
      scope = AppointmentGroup.manageable_by(@current_user)
      scope = scope.current_or_undated unless value_to_boolean(params[:include_past_appointments])
    else
      scope = AppointmentGroup.reservable_by(@current_user)
      scope = scope.current unless value_to_boolean(params[:include_past_appointments])
    end
    groups = Api.paginate(
      scope.order('id'),
      self,
      api_v1_appointment_groups_path(:scope => params[:scope])
    )
    AppointmentGroup.send(:preload_associations, groups, :appointments) if params[:include]
    render :json => groups.map{ |group| appointment_group_json(group, @current_user, session, :include => params[:include]) }
  end

  # @API Create an appointment group
  #
  # Create and return a new appointment group. If new_appointments are
  # specified, the response will return a new_appointments array (same format
  # as appointments array, see "List appointment groups" action)
  #
  # @argument appointment_group[context_codes][] [Required] Array of context codes (courses, e.g. course_1) this group should be linked to (1 or more). Users in the course(s) with appropriate permissions will be able to sign up for this appointment group.
  # @argument appointment_group[sub_context_codes][] [Optional] Array of sub context codes (course sections or a single group category) this group should be linked to. Used to limit the appointment group to particular sections. If a group category is specified, students will sign up in groups and the participant_type will be "Group" instead of "User".
  # @argument appointment_group[title] [Optional] Short title for the appointment group.
  # @argument appointment_group[description] [Optional] Longer text description of the appointment group.
  # @argument appointment_group[location_name] [Optional] Location name of the appointment group.
  # @argument appointment_group[location_address] [Optional] Location address.
  # @argument appointment_group[publish] [Optional] Boolean, default false. Indicates whether this appointment group should be published (i.e. made available for signup). Once published, an appointment group cannot be unpublished.
  # @argument appointment_group[participants_per_appointment] [Optional] Maximum number of participants that may register for each time slot. Defaults to null (no limit).
  # @argument appointment_group[min_appointments_per_participant] [Optional] Minimum number of time slots a user must register for. If not set, users do not need to sign up for any time slots.
  # @argument appointment_group[max_appointments_per_participant] [Optional] Maximum number of time slots a user may register for.
  # @argument appointment_group[new_appointments][X][] [Optional] Nested array of start time/end time pairs indicating time slots for this appointment group. Refer to the example request.
  # @argument appointment_group[participant_visibility] [Optional, "private"|"protected"] "private" means participants cannot see who has signed up for a particular time slot, "protected" means that they can. Defaults to "private".
  #
  # @example_request
  #
  #   curl 'http://<canvas>/api/v1/appointment_groups.json' \ 
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
    params[:appointment_group][:contexts] = contexts
    @group = AppointmentGroup.new(params[:appointment_group])
    @group.update_contexts_and_sub_contexts
    if authorized_action(@group, @current_user, :manage)
      if @group.save
        @group.publish! if publish
        render :json => appointment_group_json(@group, @current_user, session), :status => :created
      else
        render :json => @group.errors.to_json, :status => :bad_request
      end
    end
  end

  # @API Get a single appointment group
  #
  # Returns information for a single appointment group
  #
  # @argument include[] [Optional] Array of additional information to include.
  #   Allowable values include "child_events" (i.e. reservations of time slots
  #   time slots). "appointments" will always be returned (see include[]
  #   argument of "List appointment groups" action).
  def show
    if authorized_action(@group, @current_user, :read)
      unless request.format == :json
        anchor = calendar_fragment :view_name => :scheduler, :appointment_group_id => @group.id
        return redirect_to calendar2_url(:anchor => anchor)
      end

      render :json => appointment_group_json(@group, @current_user, session, :include => ((params[:include] || []) | ['appointments']))
    end
  end

  # @API Update an appointment group
  #
  # Update and return an appointment group. If new_appointments are specified,
  # the response will return a new_appointments array (same format as
  # appointments array, see "List appointment groups" action).
  #
  # @argument appointment_group[context_codes][] [Optional] Array of context codes to add to this appointment group (existing ones cannot be removed).
  # @argument appointment_group[sub_context_codes][] [Optional] Array of sub context codes to add to this appointment group (existing ones cannot be removed).
  # @argument appointment_group[title] [Optional] Short title for the appointment group.
  # @argument appointment_group[description] [Optional] Longer text description of the appointment group.
  # @argument appointment_group[location_name] [Optional] Location name of the appointment group.
  # @argument appointment_group[location_address] [Optional] Location address.
  # @argument appointment_group[publish] [Optional] Boolean, default false. Indicates whether this appointment group should be published (i.e. made available for signup). Once published, an appointment group cannot be unpublished.
  # @argument appointment_group[participants_per_appointment] [Optional] Maximum number of participants that may register for each time slot. Defaults to null (no limit). Changes will not affect existing reservations.
  # @argument appointment_group[min_appointments_per_participant] [Optional] Minimum number of time slots a user must register for. If not set, users do not need to sign up for any time slots. Changes will not affect existing reservations.
  # @argument appointment_group[max_appointments_per_participant] [Optional] Maximum number of time slots a user may register for. Changes will not affect existing reservations.
  # @argument appointment_group[new_appointments][X][] [Optional] Nested array of new start time/end time pairs indicating time slots for this appointment group. Refer to the example request. To remove existing time slots or reservations, use the Calendar Event API.
  # @argument appointment_group[participant_visibility] [Optional, "private"|"protected"] "private" means participants cannot see who has signed up for a particular time slot, "protected" means that they can.
  #
  # @example_request
  #
  #   curl 'http://<canvas>/api/v1/appointment_groups/543.json' \ 
  #        -X PUT \ 
  #        -F 'appointment_group[publish]=1' \
  #        -H "Authorization: Bearer <token>"
  def update
    contexts = get_contexts
    @group.contexts = contexts if contexts
    if authorized_action(@group, @current_user, :update)
      publish = params[:appointment_group].delete(:publish) == "1"
      if @group.update_attributes(params[:appointment_group])
        @group.publish! if publish
        render :json => appointment_group_json(@group, @current_user, session)
      else
        render :json => @group.errors.to_json, :status => :bad_request
      end
    end
  end

  # @API Delete an appointment group
  #
  # Delete an appointment group (and associated time slots and reservations) 
  # and return the deleted group
  #
  # @argument cancel_reason [Optional] Reason for deleting/canceling the
  # appointment group.
  #
  # @example_request
  #
  #   curl 'http://<canvas>/api/v1/appointment_groups/543.json' \ 
  #        -X DELETE \ 
  #        -F 'cancel_reason=El Tigre Chino got fired' \ 
  #        -H "Authorization: Bearer <token>"
  def destroy
    if authorized_action(@group, @current_user, :delete)
      @group.cancel_reason = params[:cancel_reason]
      if @group.destroy
        render :json => appointment_group_json(@group, @current_user, session)
      else
        render :json => @group.errors.to_json, :status => :bad_request
      end
    end
  end

  # @API List user participants
  #
  # List users that are (or may be) participating in this appointment group.
  # Refer to the Users API for the response fields. Returns no results for
  # appointment groups with the "Group" participant_type.
  #
  # @argument registration_status [Optional, "all"|"registered"|"registered"]
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
  # @argument registration_status [Optional, "all"|"registered"|"registered"]
  #   Limits results to the a given participation status, defaults to "all"
  def groups
    participants('Group'){ |g| group_json(g, @current_user, session) }
  end


  protected

  def participants(type, &formatter)
    if authorized_action(@group, @current_user, :read)
      return render :json => [] unless @group.participant_type == type
      render :json => Api.paginate(
        @group.possible_participants(params[:registration_status]),
        self,
        send("api_v1_appointment_group_#{params[:action]}_path", @group)
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
end
