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

class CalendarEventsApiController < ApplicationController
  include Api::V1::CalendarEvent

  before_filter :require_user
  before_filter :get_context, :only => :create
  before_filter :get_options, :only => :index

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

  def show
    get_event(true)
    if authorized_action(@event, @current_user, :read)
      render :json => event_json(@event, @current_user, session)
    end
  end

  def reserve
    get_event(true)
    if authorized_action(@event, @current_user, :reserve)
      begin
        if params[:participant_id] && @event.appointment_group.grants_right?(@current_user, session, :manage)
          participant = @event.appointment_group.possible_participants.detect { |p| p.id == params[:participant_id].to_i }
        else
          participant = @event.appointment_group.participant_for(@current_user)
          participant = nil if participant && params[:participant_id] && params[:participant_id].to_i != participant.id
        end
        raise CalendarEvent::ReservationError, "invalid participant" unless participant
        reservation = @event.reserve_for(participant, @current_user, :cancel_existing => params[:cancel_existing])
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

  def get_context
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
    unless params[:undated]
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
    params.slice(:start_at, :end_at, :undated, :contexts, :type)
  end
end
