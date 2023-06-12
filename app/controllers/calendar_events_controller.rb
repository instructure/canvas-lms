# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

class CalendarEventsController < ApplicationController
  include CalendarConferencesHelper

  before_action :require_context
  before_action :rce_js_env, only: [:new, :edit]

  add_crumb(proc { t(:"#crumbs.calendar_events", "Calendar Events") }, only: %i[show new edit]) { |c| c.send :calendar_url_for, c.instance_variable_get(:@context) }

  def show
    @event = @context.calendar_events.find(params[:id])
    add_crumb(@event.title, named_context_url(@context, :context_calendar_event_url, @event))
    if @event.deleted?
      flash[:notice] = t "notices.deleted", "This event has been deleted"
      redirect_to calendar_url_for(@context)
      return
    end
    if authorized_action(@event, @current_user, :read)
      # If param specifies to open event on calendar, redirect to view
      if params[:calendar] == "1" || @context.is_a?(CourseSection)
        return redirect_to calendar_url_for(@event.effective_context, event: @event)
      end

      log_asset_access(@event, "calendar", "calendar")
      respond_to do |format|
        format.html
        format.json { render json: @event.as_json(permissions: { user: @current_user, session: }) }
      end
    end
  end

  def new
    @event = @context.calendar_events.temp_record
    add_crumb(t("crumbs.new", "New Calendar Event"), named_context_url(@context, :new_context_calendar_event_url))
    @event.assign_attributes(permit_params(params, [:title, :start_at, :end_at, :location_name, :location_address, web_conference: strong_anything]))
    add_conference_types_to_js_env([@context])
    authorized_action(@event, @current_user, :create) && authorize_user_for_conference(@current_user, @event.web_conference)
  end

  def create
    params[:calendar_event][:time_zone_edited] = Time.zone.name if params[:calendar_event]
    @event = @context.calendar_events.build(calendar_event_params)
    if authorized_action(@event, @current_user, :create) && authorize_user_for_conference(@current_user, @event.web_conference)
      respond_to do |format|
        @event.updating_user = @current_user
        if @event.save
          flash[:notice] = t "notices.created", "Event was successfully created."
          format.html { redirect_to calendar_url_for(@context) }
          format.json { render json: @event.as_json(permissions: { user: @current_user, session: }), status: :created }
        else
          format.html { render :new }
          format.json { render json: @event.errors, status: :bad_request }
        end
      end
    end
  end

  def edit
    @event = CalendarEvent.find(params[:id])
    event_params = permit_params(params, [:title, :start_at, :end_at, :location_name, :location_address, web_conference: strong_anything])
    return unless authorize_user_for_conference(@current_user, event_params[:web_conference])

    if authorized_action(@event, @current_user, :update_content)
      add_conference_types_to_js_env([@context])
      render :new
    end
  end

  def update
    @event = CalendarEvent.find(params[:id])
    if authorized_action(@event, @current_user, :update)
      respond_to do |format|
        params_for_update = calendar_event_params
        params_for_update[:calendar_event][:time_zone_edited] = Time.zone.name if params_for_update[:calendar_event]
        return unless authorize_user_for_conference(@current_user, params_for_update[:web_conference])

        @event.updating_user = @current_user
        if @event.update(params_for_update)
          log_asset_access(@event, "calendar", "calendar", "participate")
          flash[:notice] = t "notices.updated", "Event was successfully updated."
          format.html { redirect_to calendar_url_for(@context) }
          format.json { render json: @event.as_json(permissions: { user: @current_user, session: }), status: :ok }
        else
          format.html { render :edit }
          format.json { render json: @event.errors, status: :bad_request }
        end
      end
    end
  end

  def destroy
    @event = @context.calendar_events.find(params[:id])
    if authorized_action(@event, @current_user, :delete)
      @event.cancel_reason = params[:cancel_reason]
      @event.destroy
      respond_to do |format|
        format.html { redirect_to calendar_url_for(@context) }
        format.json { render json: @event, status: :ok }
      end
    end
  end

  protected

  def feature_context
    case @context
    when User
      @domain_root_account
    when Group
      @context.context
    else
      @context
    end
  end

  def calendar_event_params
    permit_params(
      params.require(:calendar_event),
      CalendarEvent.permitted_attributes + [child_event_data: strong_anything, web_conference: strong_anything]
    )
  end

  def permit_params(params, attrs)
    params.permit(attrs).tap do |p|
      if p.key?(:web_conference)
        p[:web_conference] = find_or_initialize_conference(@context, p[:web_conference])
      end
    end
  end
end
