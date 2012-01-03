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

class AppointmentGroupsController < ApplicationController
  include Api::V1::CalendarEvent

  before_filter :require_user
  before_filter :get_context, :only => :create
  before_filter :get_appointment_group, :only => [:show, :update, :destroy]

  def index
    # TODO: fragment hash fu to load appointment groups
    return redirect_to calendar2_url unless request.format == :json

    if params[:scope] == 'manageable'
      scope = AppointmentGroup.manageable_by(@current_user)
      scope = scope.current_or_undated unless params[:include_past_appointments]
    else
      scope = AppointmentGroup.reservable_by(@current_user)
      scope = scope.current unless params[:include_past_appointments]
    end
    groups = Api.paginate(
      scope.order('id'),
      self,
      api_v1_appointment_groups_path(:scope => params[:scope])
    )
    AppointmentGroup.send(:preload_associations, groups, :appointments) if params[:include]
    render :json => groups.map{ |group| appointment_group_json(group, @current_user, session, :include => params[:include]) }
  end

  def create
    publish = params[:appointment_group].delete(:publish) == '1'
    @group = @context.appointment_groups.build(params[:appointment_group])
    if authorized_action(@group, @current_user, :manage)
      if @group.save
        @group.publish! if publish
        render :json => appointment_group_json(@group, @current_user, session), :status => :created
      else
        render :json => @group.errors.to_json, :status => :bad_request
      end
    end
  end

  def show
    if authorized_action(@group, @current_user, :read)
      # TODO: fragment hash fu to load the appointment group
      return redirect_to calendar2_url unless request.format == :json

      render :json => appointment_group_json(@group, @current_user, session, :include => ((params[:include] || []) | ['appointments']))
    end
  end

  def update
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

  def destroy
    if authorized_action(@group, @current_user, :delete)
      if @group.destroy
        render :json => appointment_group_json(@group, @current_user, session)
      else
        render :json => @group.errors.to_json, :status => :bad_request
      end
    end
  end


  protected

  def get_context
    @context = Context.find_by_asset_string(params[:appointment_group].delete(:context_code)) if params[:appointment_group] && params[:appointment_group][:context_code]
    raise ActiveRecord::RecordNotFound unless @context
  end

  def get_appointment_group
    @group = AppointmentGroup.find(params[:id].to_i)
    @context = @group.context
  end
end
