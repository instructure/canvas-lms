# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

module Lti
  class Launch
    FRAME_ALLOWANCES = %w[geolocation microphone camera midi encrypted-media autoplay clipboard-write display-capture].freeze

    attr_writer :analytics_id, :analytics_message_type, :resource_url
    attr_accessor :link_text, :params, :launch_type, :tool_dimensions, :base_string

    def self.iframe_allowances
      FRAME_ALLOWANCES.map { |s| "#{s} *" }
    end

    def initialize(options = {})
      @post_only = options[:post_only]
      @tool_dimensions = options[:tool_dimensions] || { selection_height: "100%", selection_width: "100%" }
    end

    def post_message_token
      @_post_message_token ||= SecureRandom.uuid
    end

    def resource_url
      url = URI(@resource_url)

      if ["http", "https"].include?(url.scheme)
        @post_only ? @resource_url.split("?").first : @resource_url
      else
        "about:blank"
      end
    rescue
      "about:blank"
    end

    def resource_path
      url = URI.parse(resource_url)
      url.path.presence || "/"
    end

    def analytics_id
      @analytics_id || URI.parse(resource_url).host || "unknown"
    end

    def analytics_message_type
      @analytics_message_type ||
        ((params["lti_message_type"] == "basic-lti-launch-request") ? "tool_launch" : params["lti_message_type"]) ||
        "tool_launch"
    end
  end
end
