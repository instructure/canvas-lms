# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

class LearnPlatformController < ApplicationController
  def learnplatform_api
    @learnplatform_api ||= LearnPlatform::Api.new
  end

  def index
    options = {
      page: params[:page] || 1,
      per_page: params[:per_page] || 20
    }
    options[:q] = params[:q].to_unsafe_h if params[:q]

    response = learnplatform_api.products(options)

    return render json: response, status: :internal_server_error if response.key?(:lp_server_error)

    render json: response
  end

  def index_by_category
    response = learnplatform_api.products_by_category

    return render json: response, status: :internal_server_error if response.key?(:lp_server_error)

    render json: response
  end

  def show
    response = learnplatform_api.product(params[:id])

    return render json: response, status: :internal_server_error if response.key?(:lp_server_error)

    render json: response
  end

  def filters
    response = learnplatform_api.product_filters

    return render json: response, status: :internal_server_error if response.key?(:lp_server_error)

    render json: response
  end
end
