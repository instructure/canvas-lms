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
    params[:q][:canvas_integrated_only] = true
    options[:q] = params[:q].to_unsafe_h if params[:q]
    set_translate_lang_option(options)

    response = learnplatform_api.products(options)

    return render json: response, status: :internal_server_error if response.key?(:lp_server_error)

    render json: response
  end

  def index_by_category
    options = {}
    set_translate_lang_option(options)
    response = learnplatform_api.products_by_category(options)

    return render json: response, status: :internal_server_error if response.key?(:lp_server_error)

    render json: response
  end

  def show
    options = {}
    set_translate_lang_option(options)
    response = learnplatform_api.product(params[:id], options)

    return render json: response, status: :internal_server_error if response.key?(:lp_server_error)

    render json: response
  end

  def filters
    options = {}
    set_translate_lang_option(options)
    response = learnplatform_api.product_filters(options)

    return render json: response, status: :internal_server_error if response.key?(:lp_server_error)

    render json: response
  end

  def index_by_organization
    options = {
      page: params[:page] || 1,
      per_page: params[:per_page] || 20
    }
    options[:q] = params[:q].to_unsafe_h if params[:q]

    response = learnplatform_api.products_by_organization(params[:organization_salesforce_id], options)

    return render json: response, status: :internal_server_error if response.key?(:lp_server_error)

    render json: response
  end

  def custom_filters
    response = learnplatform_api.custom_filters(params[:salesforce_id])

    return render json: response, status: :internal_server_error if response.key?(:lp_server_error)

    render json: response
  end

  private

  # Set the translate_lang option if needed.
  def set_translate_lang_option(options)
    if context&.root_account&.feature_enabled?(:lti_apps_page_ai_translation) && I18n.locale.present? && I18n.locale != :en
      options[:translate_lang] = I18n.locale
    end
  end
end
