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

class AlertsController < ApplicationController
  before_filter :require_context

  def create
    if authorized_action(@context, @current_user, :manage_interaction_alerts)
      @alert = @context.alerts.build(params[:alert])
      if @alert.save
        headers['Location'] = named_context_url(@context, :context_alert_url, @alert.id)
        render :json => @alert.as_json(:include => :criteria)
      else
        render :json => @alert.errors, :status => :bad_request
      end
    end
  end

  def update
    if authorized_action(@context, @current_user, :manage_interaction_alerts)
      @alert = @context.alerts.find(params[:id])
      if @alert.update_attributes(params[:alert])
        headers['Location'] = named_context_url(@context, :context_alert_url, @alert.id)
        render :json => @alert.as_json(:include => :criteria)
      else
        render :json => @alert.errors, :status => :bad_request
      end
    end
  end

  def destroy
    if authorized_action(@context, @current_user, :manage_interaction_alerts)
      @alert = @context.alerts.find(params[:id])
      @alert.destroy
      render :json => @alert
    end
  end
end
