#
# Copyright (C) 2018 - present Instructure, Inc.
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

require 'atom'

class ObserverAlertsApiController < ApplicationController
  include Api::V1::ObserverAlert

  before_action :require_user

  def alerts_by_student
    all_alerts = @current_user.
      as_observer_observer_alerts.
      active.
      where(student: params[:student_id]).
      order(id: :desc).
      select(&:users_are_still_linked?)

    alerts = Api.paginate(all_alerts, self, api_v1_observer_alerts_by_student_url)

    render json: alerts.map { |alert| observer_alert_json(alert, @current_user, session) }
  end

  def alerts_count
    all_alerts = if params[:student_id]
                   ObserverAlert.unread.where(observer: @current_user, student: params[:student_id])
                 else
                   ObserverAlert.unread.where(observer: @current_user)
                 end

    alerts = all_alerts.select(&:users_are_still_linked?)

    render json: { unread_count: alerts.count }
  end

  def update
    alert = ObserverAlert.find(params[:observer_alert_id])
    return render_unauthorized_action unless alert.observer_id == @current_user.id && alert.users_are_still_linked?

    case params[:workflow_state]
    when 'read'
      alert.workflow_state = 'read'
    when 'dismissed'
      alert.workflow_state = 'dismissed'
    end

    if alert.save
      render json: observer_alert_json(alert, @current_user, session)
    else
      render(json: alert.errors, status: :bad_request)
    end
  end
end