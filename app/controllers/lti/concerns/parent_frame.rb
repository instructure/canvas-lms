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

# Methods for controller actions which take a parent_frame_context param to
# facilitate embedding inside trusted tools (e.g. New Quizzes). Depending on
# the action then may need to one or both of these things:
# 1. Set the origin to be used with postMessage to allow the embedded tool to
#    send messages to the embedding (trusted) tool (usually set in js_env to
#    the value of parent_frame_origin)
# 2. Add the embedding tool's host to the Content-Security-Policy (CSP)
#    header's frame-ancestor directive to allow the page to me loaded in an
#    iframe embedded in the embedding tool. For this, call
#    set_extra_csp_frame_ancestor!
module Lti::Concerns
  module ParentFrame
    private

    # Can be overridden by controller if the parent_frame_context (tool ID)
    # comes from someplace else (as it does for DeepLinkingController)
    def parent_frame_context
      params[:parent_frame_context]
    end

    # Finds the tool with id parent_frame_context and returns the origin
    # (host/scheme/port based off of URL/domain) of that tool if it exists.
    # otherwise returns nil. Memoized.
    def parent_frame_origin
      return @parent_frame_origin if defined?(@parent_frame_origin)

      # Don't look up tools for unauthenticated users
      return nil unless @current_user && @current_pseudonym

      tool = parent_frame_context.presence && ContextExternalTool.find_by(id: parent_frame_context)

      @parent_frame_origin =
        if !tool&.active? || !tool&.developer_key&.internal_service ||
           !tool.context&.grants_any_right?(@current_user, session, :read, :launch_external_tool)
          nil
        elsif tool.url
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

    def set_extra_csp_frame_ancestor!
      # require http/https URI (e.g., no 'data' uris') & don't allow potential
      # specially characters that could mess up header
      if parent_frame_origin&.match(/^https?:[^ *;]+$/)
        csp_frame_ancestors << parent_frame_origin
      end
    end
  end
end
