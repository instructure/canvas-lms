# frozen_string_literal: true

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

module LearnPlatform
  module GlobalApi
    GET_UNIFIED_TOOL_ID_ENDPOINT = "/api/v2/lti/global_products/unified_tool_id"
    POST_UNIFIED_TOOL_ID_BULK_LOAD_CALLBACK_ENDPOINT = "/api/v2/lti/unified_tool_id_bulk_load"

    def self.credentials
      @credentials ||= Rails.application.credentials.learn_platform_creds&.with_indifferent_access || {}
    end

    def self.config
      @config ||= DynamicSettings.find("learn_platform_global_api", service: "canvas")
    end

    def self.endpoint
      @endpoint ||= config[:url]&.chomp("/")
    end

    def self.enabled?
      !!config[:enabled_for_canvas]
    end

    def self.auth_headers
      { Authorization: "Basic #{credentials[:learn_platform_basic_token]}" }
    end

    def self.get_unified_tool_id(lti_name:, lti_tool_id:, lti_domain:, lti_version:, lti_url:, integration_type: nil, lti_redirect_url: nil)
      return unless enabled?

      params = {
        lti_name:,
        lti_tool_id:,
        lti_domain:,
        lti_version:,
        lti_url:,
        integration_type:,
        lti_redirect_url:
      }

      encoded_params = URI.encode_www_form(params)
      url = "#{endpoint}#{GET_UNIFIED_TOOL_ID_ENDPOINT}?#{encoded_params}"
      response = CanvasHttp.get(url, auth_headers)

      if response.is_a?(Net::HTTPSuccess)
        InstStatsd::Statsd.distributed_increment("learn_platform_api.success", tags: { event_type: "get_unified_tool_id" })
        JSON.parse(response.body, symbolize_names: true)[:unified_tool_id]
      else
        InstStatsd::Statsd.distributed_increment("learn_platform_api.error.http_failure", tags: { event_type: "get_unified_tool_id", status_code: response.code })
        false
      end
    rescue CanvasHttp::Error
      InstStatsd::Statsd.distributed_increment("learn_platform_api.error", tags: { event_type: "get_unified_tool_id" })
      false
    end

    def self.post_unified_tool_id_bulk_load_callback(id:, region:, shard_issues:, row_stats:, error:)
      url = "#{endpoint}#{POST_UNIFIED_TOOL_ID_BULK_LOAD_CALLBACK_ENDPOINT}"
      payload = { id:, region:, row_stats:, shard_issues:, error: }.compact
      CanvasHttp.post(url, auth_headers, content_type: "application/json", body: payload.to_json) do |resp|
        unless resp.is_a?(Net::HTTPSuccess)
          raise CanvasHttp::InvalidResponseCodeError, resp.code
        end
      end
    end
  end
end
