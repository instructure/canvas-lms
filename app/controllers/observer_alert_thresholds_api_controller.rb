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

class ObserverAlertThresholdsApiController < ApplicationController
  include Api::V1::ObserverAlertThreshold

  before_action :require_user

  def index
    thresholds = if params[:student_id]
                   student_id = params[:student_id]
                   link = @current_user.as_observer_observation_links.active.where(student: student_id).take
                   return render_unauthorized_action unless link
                   link.observer_alert_thresholds.active
                 else
                   links = @current_user.as_observer_observation_links.active
                   return render_unauthorized_action unless links.count > 0
                   links.map { |uol| uol.observer_alert_thresholds.active }.flatten
                 end

    render json: thresholds.map { |threshold| observer_alert_threshold_json(threshold, @current_user, session) }
  end

  def show
    threshold = ObserverAlertThreshold.active.find(params[:observer_alert_threshold_id])
    link = @current_user.as_observer_observation_links.select { |uol| uol.id == threshold.user_observation_link.id }
    return render_unauthorized_action unless link.count > 0
    render json: observer_alert_threshold_json(threshold, @current_user, session)
  end

  def create
    student_id = params[:student_id]
    link = UserObservationLink.where(observer_id: @current_user, user_id: student_id).take
    return render_unauthorized_action unless link

    attrs = create_params.merge(user_observation_link: link)
    begin
      threshold = link.observer_alert_thresholds.create(attrs)
      render json: observer_alert_threshold_json(threshold, @current_user, session)
    rescue ActiveRecord::NotNullViolation
      render :json => ['missing required parameters'], :status => :bad_request
    end
  end

  def update
    threshold = ObserverAlertThreshold.active.find(params[:observer_alert_threshold_id])
    link = @current_user.as_observer_observation_links.select { |uol| uol.id == threshold.user_observation_link.id }
    return render_unauthorized_action unless link.count > 0
    threshold.update(update_params)
    render json: observer_alert_threshold_json(threshold.reload, @current_user, session)
  end

  def destroy
    threshold = ObserverAlertThreshold.active.find(params[:observer_alert_threshold_id])
    link = @current_user.as_observer_observation_links.select { |uol| uol.id == threshold.user_observation_link.id }
    return render_unauthorized_action unless link.count > 0
    threshold.destroy
    render json: observer_alert_threshold_json(threshold, @current_user, session)
  end

  def create_params
    params.require(:observer_alert_threshold).permit(:alert_type, :threshold)
  end

  def update_params
    params.require(:observer_alert_threshold).permit(:threshold)
  end
end