# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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
  class EulaLaunchController < ApplicationController
    include Lti::LaunchServices

    before_action :require_tool
    before_action :require_context
    before_action { require_feature_enabled :lti_asset_processor }
    before_action :require_access_to_context
    before_action :require_1_3_tool

    def launch_eula
      @lti_launch = create_and_log_launch(
        message_type: LtiAdvantage::Messages::EulaRequest::MESSAGE_TYPE,
        return_url: url_for(context),
        adapter_opts: {
          launch_url: tool.eula_launch_url,
        }
      )
      render Lti::AppUtil.display_template("borderless")
    end

    private

    def tool
      @tool ||= ContextExternalTool.find(params.require(:context_external_tool_id))
    end

    def context
      @context ||= get_context
    end

    def require_tool
      not_found unless tool
    end
  end
end
