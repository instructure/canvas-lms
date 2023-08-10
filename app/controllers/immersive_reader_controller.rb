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

# This API requires Immersive Reader to be configured

class ImmersiveReaderController < ApplicationController
  before_action :require_user
  before_action :require_config

  class ServiceError < StandardError; end

  def authenticate
    response = CanvasHttp.post(service_url, headers, form_data: form)

    if response && response.code == "200"
      parsed = JSON.parse(response.body)
      render json: {
        token: parsed["access_token"],
        subdomain: ir_config[:subdomain]
      }
    else
      body = begin
        JSON.parse(response.body)
      rescue JSON::ParserError
        {}
      end

      increment_error_count(response)

      message = "Error connecting to cognitive services #{body["error_description"]}"
      raise ServiceError, message
    end
  rescue ServiceError => e
    Canvas::Errors.capture_exception(:immersive_reader, e, :warn)
  end

  private

  def increment_error_count(response)
    InstStatsd::Statsd.increment(
      "immersive_reader.authentication_failure",
      tags: { status: response.code }
    )
  end

  def ir_config
    @ir_config ||= Rails.application.credentials.immersive_reader || {}
  end

  def require_config
    render json: { message: "Service not found" }, status: :not_found unless ir_config.present?
  end

  def service_url
    "https://login.windows.net/#{ir_config[:tenant_id]}/oauth2/token"
  end

  def headers
    { "content-type": "application/x-www-form-urlencoded" }
  end

  def form
    {
      grant_type: "client_credentials",
      client_id: ir_config[:client_id],
      client_secret: ir_config[:client_secret],
      resource: "https://cognitiveservices.azure.com/"
    }
  end
end
