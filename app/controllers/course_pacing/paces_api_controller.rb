# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

class CoursePacing::PacesApiController < ApplicationController
  before_action :load_contexts
  before_action :require_feature_flag
  before_action :authorize_action

  include Api::V1::Progress

  def show
    pace = pacing_service.pace_for(context, should_duplicate: true)
    return not_found if pace.nil?

    render json: {
      pace: pacing_presenter.new(pace).as_json,
      progress: pace.id ? progress_json(pacing_service.progress(pace, publish: false), @current_user, session) : nil
    }
  end

  def create
    pace = pacing_service.create_in_context(context)
    return not_found if pace.nil?

    render json: {
             pace: pacing_presenter.new(pace).as_json,
             progress: progress_json(pacing_service.progress(pace), @current_user, session)
           },
           status: :created
  end

  def update
    pace = pacing_service.pace_in_context(context)
    return not_found if pace.nil?

    if pacing_service.update_pace(pace, update_params)
      render json: {
        pace: pacing_presenter.new(pace).as_json,
        progress: progress_json(pacing_service.progress(pace), @current_user, session)
      }
    else
      render json: { success: false, errors: pace.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def delete
    # make sure the pace exists and it is valid
    pace = pacing_service.pace_in_context(context)
    return not_found if pace.nil?

    pacing_service.delete_in_context(context)
    head :no_content
  end

  private

  def update_params
    params.require(:pace).permit(
      :end_date,
      :exclude_weekends,
      :hard_end_dates,
      :workflow_state,
      course_pace_module_items_attributes: %i[id duration module_item_id root_account_id]
    )
  end

  def pacing_service
    raise NotImplementedError
  end

  def pacing_presenter
    raise NotImplementedError
  end

  def course
    raise NotImplementedError
  end

  def context
    raise NotImplementedError
  end

  def authorize_action
    authorized_action(course, @current_user, [:manage_content, :manage_course_content_edit])
  end

  def load_contexts
    raise NotImplementedError
  end

  def require_feature_flag
    not_found unless Account.site_admin.feature_enabled?(:course_paces_redesign)
  end
end
