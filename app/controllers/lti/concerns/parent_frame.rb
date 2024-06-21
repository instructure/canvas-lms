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
#    header's frame-ancestor directive to allow the page to be loaded in an
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
      return nil if parent_frame_context.blank?

      validate_parent_frame_context

      tool = ContextExternalTool.find_by(id: parent_frame_context)

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

    # Tools sometimes may mangle the parent_frame_context header if
    # they do not account for query parameters present in the launch
    # or content return URL. This will result in this request being
    # blocked by browsers since the CSP header is not correct. When
    # this happens, log an ErrorReport to give admins visibility.
    def validate_parent_frame_context
      return if Api::ID_REGEX.match?(parent_frame_context.to_s)

      extra = {
        query_params: request.query_parameters,
        message: "Invalid CSP header for nested LTI launch",
        comments: <<~TEXT
          Nested LTI launch likely failed. Check query parameters,
          tool may have ignored query string in launch/content return URL.
        TEXT
      }
      CanvasErrors.capture(:invalid_parent_frame_context, { extra: })
    end

    def override_parent_frame_origin(url)
      uri = URI.parse(url)
      origin = URI("#{uri.scheme}://#{uri.host}:#{uri.port}")
      origin.to_s
    end

    def set_extra_csp_frame_ancestor!(origin = nil)
      origin ||= parent_frame_origin

      # require http/https URI (e.g., no 'data' uris') & don't allow potential
      # special characters that could mess up header
      if origin&.match(/^https?:[^ *;]+$/)
        csp_frame_ancestors << origin
      end
    end

    # In some situations for nested LTI tools, such as if the nested tool needs
    # to go thru an OAuth flow, parent_frame_context is not available. In these
    # scenarios, we can allow the Canvas page (e.g. OAuth confirm page) to be
    # framed inside any trusted tool for the root account. (This requires the
    # outer tool to be installed at the root account, as is the case for NQ)
    def allow_trusted_tools_to_embed_this_page!
      @domain_root_account&.cached_tool_domains(internal_service_only: true)&.each do |domain|
        set_extra_csp_frame_ancestor! "https://#{domain}"
        set_extra_csp_frame_ancestor! "http://#{domain}" if Rails.env.development?
      end
    end
  end
end
