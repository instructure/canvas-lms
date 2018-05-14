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
    link = @current_user.as_observer_observation_links.active.where(student: params[:student_id]).take
    return render_unauthorized_action unless link

    alerts = Api.paginate(link.observer_alerts.active, self, api_v1_observer_alerts_by_student_url)

    render json: alerts.map { |alert| observer_alert_json(alert, @current_user, session) }
  end

  def alerts_count
    links = UserObservationLink.active.where(observer: @current_user)
    links = links.where(user_id: params[:student_id]) if params[:student_id]

    return render_unauthorized_action unless links.count > 0

    alerts = ObserverAlert.unread.where(user_observation_link: links)

    render json: { unread_count: alerts.count }
  end
end