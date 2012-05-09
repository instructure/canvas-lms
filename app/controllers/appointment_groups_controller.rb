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
  before_filter :get_appointment_group, :only => [:show, :update, :destroy, :users, :groups]

  def calendar_fragment(opts)
    opts.to_json.unpack('H*')
  end
  private :calendar_fragment

  def index
    unless request.format == :json
      anchor = calendar_fragment :view_name => :scheduler
      return redirect_to calendar2_url(:anchor => anchor)
    end

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
    contexts = get_contexts
    raise ActiveRecord::RecordNotFound unless contexts.present?

    publish = params[:appointment_group].delete(:publish) == '1'
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

  def show
    if authorized_action(@group, @current_user, :read)
      unless request.format == :json
        anchor = calendar_fragment :view_name => :scheduler, :appointment_group_id => @group.id
        return redirect_to calendar2_url(:anchor => anchor)
      end

      render :json => appointment_group_json(@group, @current_user, session, :include => ((params[:include] || []) | ['appointments']))
    end
  end

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

  def users
    participants('User'){ |u| user_json(u, @current_user, session) }
  end

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
