# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

class GradebookFiltersApiController < ApplicationController
  before_action :require_user
  before_action :require_context
  before_action :load_gradebook_filter, except: [:index, :create]

  def index
    gradebook_filters = @context.gradebook_filters.where(user: @current_user).order(:created_at)
    render json: gradebook_filters.as_json
  end

  def show
    return unless authorized_action(@gradebook_filter, @current_user, :read)

    render json: @gradebook_filter.as_json, status: :created
  end

  def create
    gradebook_filter = @context.gradebook_filters.build(gradebook_filter_params.merge(user: @current_user))
    if gradebook_filter.save
      render json: gradebook_filter
    else
      render json: gradebook_filter.errors, status: :bad_request
    end
  end

  def update
    return unless authorized_action(@gradebook_filter, @current_user, :update)

    if @gradebook_filter.update(gradebook_filter_params)
      render json: @gradebook_filter
    else
      render json: @gradebook_filter.errors, status: :bad_request
    end
  end

  def destroy
    return unless authorized_action(@gradebook_filter, @current_user, :destroy)

    @gradebook_filter.destroy
    render json: @gradebook_filter.as_json, status: :ok
  end

  protected

  def load_gradebook_filter
    @gradebook_filter = @context.gradebook_filters.find_by!(id: params[:id], user: @current_user)
  end

  def gradebook_filter_params
    params.require(:gradebook_filter).permit(:name, payload: strong_anything)
  end
end
