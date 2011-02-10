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

class RoleOverridesController < ApplicationController
  before_filter :require_context

  def index
    if authorized_action(@context, @current_user, :manage_role_overrides)
      @role_types = RoleOverride.enrollment_types
      @role_types = RoleOverride.account_membership_types(@context) if @context.is_a?(Account) && params[:account_roles]
      @managing_account_roles = @context.is_a?(Account) && (params[:account_roles] || @context.site_admin?)
      respond_to do |format|
        format.html
      end
    end
  end
  
  def add_role
    if authorized_action(@context, @current_user, :manage_role_overrides)
      @context.add_account_membership_type(params[:role_type])
      redirect_to named_context_url(@context, :context_role_overrides_url, :account_roles => params[:account_roles])
    end
  end
  
  def remove_role
    if authorized_action(@context, @current_user, :manage_role_overrides)
      @context.remove_account_membership_type(params[:role])
      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_role_overrides_url, :account_roles => '1') }
        format.json { render :json => @context.to_json(:only => [:membership_types, :id]) }
      end
    end
  end

  def create
    if authorized_action(@context, @current_user, :manage_role_overrides)
      @role_types = RoleOverride.enrollment_types
      @role_types = RoleOverride.account_membership_types(@context) if @context.is_a?(Account) && params[:account_roles]
      if params[:permissions]
        RoleOverride.permissions.each_pair do |key, permission|
          if params[:permissions][key]
            @role_types.each do |enrollment_type|
              enrollment_type = enrollment_type[:name]
              if params[:permissions][key][enrollment_type]
                keep = false
                role_override = @context.role_overrides.find_or_initialize_by_permission_and_enrollment_type({
                  :permission => key.to_s, 
                  :enrollment_type => enrollment_type
                })
                if params[:permissions][key][enrollment_type][:override] && ['checked', 'unchecked'].include?( params[:permissions][key][enrollment_type][:override] )
                  role_override.enabled = params[:permissions][key][enrollment_type][:override] == 'checked'
                  keep = true
                end
                if params[:permissions][key][enrollment_type][:locked]
                  role_override.locked = params[:permissions][key][enrollment_type][:locked] == 'true'
                  keep = true if role_override.locked
                end
                keep ? role_override.save! : role_override.destroy
              end
            end
          end
        end
      end
      flash[:notice] = 'Changes Saved Successfully.'
      redirect_to named_context_url(@context, :context_role_overrides_url, :account_roles => params[:account_roles])
    end
  end
end
