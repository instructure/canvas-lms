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

class NotificationsController < ApplicationController
  before_filter :require_user, :require_context
  
  def destroy
    @notification = @current_user.dashboard_messages.find(params[:id]) rescue nil
    @notification.workflow_state = "closed" if @notification
    @notification.save! if @notification
    render :json => @notification.to_json
  end
  
  def update
    @notification = @current_user.dashboard_messages.find(params[:id])
    @notification.workflow_state = "dashboard"
    @notification.save!
    render :json => @notification.to_json
  end
  
  def clear
    @messages = @current_user.dashboard_messages.in_state('dashboard')
    @messages = @messages.find_all_by_asset_context_id_and_asset_context_type(@context.id, @context.class.to_s) if @context != @current_user
    if params[:category]
      @messages = @messages.select{|m| m.category == params[:category]}
    end
    Message.transaction do 
      @messages.each {|m| m.close! rescue nil }
    end
    render :json => @messages.to_json
  end
end
