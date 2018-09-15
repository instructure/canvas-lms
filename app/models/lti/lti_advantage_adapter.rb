#
# Copyright (C) 2018 - present Instructure, Inc.
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
  class LtiAdvantageAdapter
    delegate :generate_post_payload_for_assignment, to: :resource_link_request
    delegate :generate_post_payload_for_homework_submission, to: :resource_link_request

    def initialize(tool:, user:, context:, return_url:, expander:, opts:)
      @tool = tool
      @user = user
      @context = context
      @return_url = return_url
      @expander = expander
      @opts = opts
    end

    def generate_post_payload
      message_type = @tool.extension_setting(resource_type, :message_type)

      if message_type == 'DeepLinkingRequest'
        # Use the DeepLinkingRequest message model to generate params.
      else
        resource_link_request.generate_post_payload
      end
    end

    def launch_url
      resource_type ? @tool.extension_setting(resource_type, :url) : @tool.url
    end

    private

    def resource_link_request
      @_resource_link_request ||= begin
        Lti::Messages::ResourceLinkRequest.new(
          tool: @tool,
          context: @context,
          user: @user,
          expander: @expander,
          return_url: @return_url,
          opts: @opts
        )
      end
    end

    def resource_type
      @opts[:resource_type]
    end
  end
end