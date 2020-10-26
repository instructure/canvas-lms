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
  class LtiToolCreator
    PRIVACY_LEVEL_MAP = {
        'public' => LtiOutbound::LTITool::PRIVACY_LEVEL_PUBLIC,
        'email_only' => LtiOutbound::LTITool::PRIVACY_LEVEL_EMAIL_ONLY,
        'name_only' => LtiOutbound::LTITool::PRIVACY_LEVEL_NAME_ONLY,
        'anonymous' => LtiOutbound::LTITool::PRIVACY_LEVEL_ANONYMOUS
    }
    def initialize(context_external_tool)
      @context_external_tool = context_external_tool
    end

    def convert()
      LtiOutbound::LTITool.new.tap do |lti_tool|
        lti_tool.name = @context_external_tool.name
        lti_tool.consumer_key = @context_external_tool.consumer_key
        lti_tool.shared_secret = @context_external_tool.shared_secret
        lti_tool.settings = @context_external_tool.settings

        lti_tool.privacy_level = PRIVACY_LEVEL_MAP[@context_external_tool.privacy_level] || LtiOutbound::LTITool::PRIVACY_LEVEL_ANONYMOUS
      end
    end
  end
end