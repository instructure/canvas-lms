# frozen_string_literal: true

# Copyright (C) 2024 - present Instructure, Inc.

# This file is part of Canvas.

# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.

# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.

# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

module LearnPlatform
  class Api
    attr_reader :learnplatform

    def initialize
      @learnplatform = Canvas::Plugin.find(:learnplatform)
    end

    def valid_basic_auth_params?
      learnplatform.settings["username"].present? && learnplatform.settings["password"].present? && !learnplatform.settings["username"].empty? && !learnplatform.settings["password"].empty?
    end

    def valid_token_auth_params?
      learnplatform.settings["jwt_issuer"].present? && learnplatform.settings["jwt_secret"].present? && !learnplatform.settings["jwt_issuer"].empty? && !learnplatform.settings["jwt_secret"].empty?
    end

    def valid_learnplatform?
      learnplatform.enabled? && (valid_basic_auth_params? || valid_token_auth_params?)
    end

    def fetch_learnplatform_response(endpoint, expires, params = {})
      base_url = learnplatform.settings["base_url"]

      if valid_token_auth_params?
        jwt_issuer = learnplatform.settings["jwt_issuer_dec"]
        secret = learnplatform.settings["jwt_secret_dec"]
        payload = { iss: jwt_issuer, exp: Time.now.to_i + 3600 }
        token = JWT.encode(payload, secret, "HS256")
        authorization = "Bearer #{token}"
      elsif valid_basic_auth_params?
        name = learnplatform.settings["username_dec"]
        pass = learnplatform.settings["password_dec"]
        authorization = "Basic #{Base64.encode64("#{name}:#{pass}")}"
      end

      begin
        cache_key = ["learnplatform", endpoint, authorization, params].cache_key
        json = Rails.cache.fetch(cache_key, expires_in: expires) do
          uri = URI.parse("#{base_url}#{endpoint}")
          uri.query = params.to_param unless params.empty?
          response = CanvasHttp.get(uri.to_s, { Authorization: authorization })
          json = JSON.parse(response.body)

          unless response.code.to_i / 100 == 2
            json = { lp_server_error: true, code: response.code, errors: json["errors"], json: }
          end
          json
        end
      rescue
        json = {}
        Rails.cache.delete cache_key
        raise
      end

      json
    end

    def products(params = {})
      return {} unless valid_learnplatform?

      endpoint = "/api/v2/lti/tools"
      fetch_learnplatform_response(endpoint, 1.hour, params)
    end

    def product(id, params = {})
      return {} unless valid_learnplatform?

      endpoint = "/api/v2/lti/tools/#{id}"
      fetch_learnplatform_response(endpoint, 1.hour, params)
    end

    def products_by_category(params = {})
      return {} unless valid_learnplatform?

      endpoint = "/api/v2/lti/tools_by_display_group"
      fetch_learnplatform_response(endpoint, 1.hour, params)
    end

    def product_filters(params = {})
      return {} unless valid_learnplatform?

      endpoint = "/api/v2/lti/tools_filters"
      fetch_learnplatform_response(endpoint, 1.hour, params)
    end

    def products_by_organization(organization_salesforce_id, params = {})
      return {} unless valid_learnplatform?

      endpoint = "/api/v2/lti/organizations/#{organization_salesforce_id}/tools"
      fetch_learnplatform_response(endpoint, 1.hour, params)
    end

    def custom_filters(salesforce_id)
      return {} unless valid_learnplatform?

      endpoint = "/api/v2/lti/organizations/#{salesforce_id}/tools_filters"
      fetch_learnplatform_response(endpoint, 1.hour)
    end
  end
end
