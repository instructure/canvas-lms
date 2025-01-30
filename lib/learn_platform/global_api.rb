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
    def self.credentials
      @credentials ||= Rails.application.credentials.learn_platform_creds&.with_indifferent_access || {}
    end

    def self.config
      @config ||= DynamicSettings.find("learn_platform_global_api", service: "canvas")
    end

    def self.endpoint
      @endpoint ||= config[:url]
    end

    def self.enabled?
      !!config[:enabled_for_canvas]
    end

    def self.get_unified_tool_id(lti_name:, lti_tool_id:, lti_domain:, lti_version:, lti_url:, integration_type: nil, lti_redirect_url: nil)
      return unless enabled?

      headers = { Authorization: "Basic #{credentials[:learn_platform_basic_token]}" }
      params = {
        lti_name:,
        lti_tool_id:,
        lti_domain:,
        lti_version:,
        lti_url:,
        integration_type:,
        lti_redirect_url:
      }

      suffix = "api/v2/lti/global_products/unified_tool_id"
      encoded_params = URI.encode_www_form(params)
      url = "#{endpoint}/#{suffix}?#{encoded_params}"
      response = CanvasHttp.get(url, headers)

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
  end
end
