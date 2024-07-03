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

    def initialize(context)
      @learnplatform = Canvas::Plugin.find(:learnplatform)
      @context ||= context
    end

    def valid_learnplatform?
      @learnplatform&.enabled? && !@learnplatform.settings["token"].empty?
    end

    def fetch_learnplatform_response(endpoint, expires, params = {})
      return {} unless valid_learnplatform?

      base_url = @learnplatform.settings["base_url"]
      access_token = @learnplatform.settings["token"]

      params["access_token"] = access_token

      begin
        cache_key = ["learnplatform", endpoint, access_token].cache_key
        response = Rails.cache.fetch(cache_key, expires_in: expires) do
          uri = URI.parse("#{base_url}#{endpoint}")
          uri.query = URI.encode_www_form(params)
          CanvasHttp.get(uri.to_s).body
        end

        json = JSON.parse(response)
      rescue
        json = {}
        Rails.cache.delete cache_key
      end

      json
    end

    def products(params = {})
      return {} unless valid_learnplatform?

      endpoint = "/api/v2/lti/tools"
      fetch_learnplatform_response(endpoint, 1.hour, params)
    end

    def product(id)
      return {} unless valid_learnplatform?

      endpoint = "/api/v2/lti/tools/#{id}"
      fetch_learnplatform_response(endpoint, 1.hour)
    end

    def products_by_category
      return {} unless valid_learnplatform?

      endpoint = "/api/v2/lti/tools_by_display_group"
      fetch_learnplatform_response(endpoint, 1.hour)
    end

    def product_filters
      return {} unless valid_learnplatform?

      endpoint = "/api/v2/lti/filters"
      fetch_learnplatform_response(endpoint, 1.hour)
    end
  end
end
