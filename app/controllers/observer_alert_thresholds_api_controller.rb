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
                   @current_user.as_observer_observer_alert_thresholds.active.where(student: params[:student_id])
                 else
                   @current_user.as_observer_observer_alert_thresholds.active
                 end

    thresholds = thresholds.select(&:users_are_still_linked?)

    render json: thresholds.map { |threshold| observer_alert_threshold_json(threshold, @current_user, session) }
  end

  def show
    threshold = ObserverAlertThreshold.active.find(params[:observer_alert_threshold_id])
    return render_unauthorized_action unless threshold.observer_id == @current_user.id && threshold.users_are_still_linked?
    render json: observer_alert_threshold_json(threshold, @current_user, session)
  end

  def create
    attrs = create_params
    begin
      user = api_find(User, attrs[:user_id])
    rescue
      return render json: {errors: ['user_id is invalid']}, status: :bad_request
    end

    threshold = ObserverAlertThreshold.where(observer: @current_user, student: attrs[:user_id], alert_type: attrs[:alert_type]).take
    if threshold
      # update if duplicate
      threshold.update(threshold: attrs[:threshold], workflow_state: 'active')
    else
      attrs = attrs.merge(observer: @current_user)
      threshold = ObserverAlertThreshold.create(attrs)
    end

    if threshold.valid?
      render json: observer_alert_threshold_json(threshold, @current_user, session)
    else
      render json: threshold.errors, status: :bad_request
    end
  end

  def update
    threshold = ObserverAlertThreshold.active.find(params[:observer_alert_threshold_id])
    return render_unauthorized_action unless threshold.observer_id == @current_user.id && threshold.users_are_still_linked?
    threshold.update(threshold: params[:threshold])
    render json: observer_alert_threshold_json(threshold, @current_user, session)
  end

  def destroy
    threshold = ObserverAlertThreshold.active.find(params[:observer_alert_threshold_id])
    return render_unauthorized_action unless threshold.observer_id == @current_user.id && threshold.users_are_still_linked?
    threshold.destroy
    render json: observer_alert_threshold_json(threshold, @current_user, session)
  end

  def create_params
    params.require(:observer_alert_threshold).permit(:alert_type, :threshold, :user_id)
  end
end
