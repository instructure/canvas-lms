# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

module Lti::Concerns
  module ParentFrame
    extend ActiveSupport::Concern

    # Takes an id of a tool and returns the origin of that tool if it exists
    # otherwise returns nil
    def parent_frame_origin(tool_id)
      tool = tool_id ? ContextExternalTool.find_by(id: tool_id) : nil
      return nil unless tool&.active? && tool&.developer_key&.internal_service

      if tool.url
        override_parent_frame_origin(tool.url)
      elsif tool.domain
        "https://#{tool.domain}"
      end
    end

    def override_parent_frame_origin(url)
      uri = URI.parse(url)
      origin = URI("#{uri.scheme}://#{uri.host}:#{uri.port}")
      origin.to_s
    end
  end
end
