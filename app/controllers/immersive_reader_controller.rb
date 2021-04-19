# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

# @API Immersive Reader
# @beta
#
# This API requires Immersive Reader to be configured

class ImmersiveReaderController < ApplicationController

  before_action :require_user
  before_action :require_config

  def ir_config
    @ir_config ||= YAML.load(Canvas::DynamicSettings.find(tree: :private)['immersive_reader.yml'] || '{}')
  end

  def require_config
    return render json: { message: 'Service not found' }, status: :not_found unless ir_config.present?
  end

  def service_url
    "https://login.windows.net/#{ir_config[:ir_tenant_id]}/oauth2/token"
  end

  def headers
    { "content-type": "application/x-www-form-urlencoded" }
  end

  def form
    {
      grant_type: "client_credentials",
      client_id: ir_config[:ir_client_id],
      client_secret: ir_config[:ir_client_secret],
      resource: "https://cognitiveservices.azure.com/"
    }
  end

  def authenticate
    response = CanvasHttp.post(service_url, headers, form_data: form)
    if response && response.code == '200'
      parsed = JSON.parse(response.body)
      render json: {
        token: parsed["access_token"],
        subdomain: ir_config[:ir_subdomain]
      }
    else
      message = "Error connecting to cognitive services #{response}"
      raise ServiceError, message
    end
  end
end
