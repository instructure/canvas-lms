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
  # This module provides common functionality for launching LTI tools
  # It provides methods to create Launch object, build JWT messages, and log launches
  # It can be included in controllers that renders Lti launches
  # such as AssetProcessorLaunchController and EulaLaunchController
  #
  # Usage example:
  # ```ruby
  # include Lti::LaunchServices
  #
  # def launch_tool
  #   @lti_launch = create_and_log_launch(
  #     message_type: LtiAdvantage::Messages::XY::MESSAGE_TYPE,
  #     return_url: context_url
  #   )
  #   render Lti::AppUtil.display_template("borderless")
  # end
  # ```
  module LaunchServices
    def context
      raise "Abstract Method"
    end

    def tool
      raise "Abstract Method"
    end

    def create_and_log_launch(message_type:, return_url:, adapter_opts: {}, expander_opts: {}, log_launch_type: :direct_link)
      lti_launch = Lti::Launch.new
      lti_launch.link_text = tool.default_label
      lti_launch.analytics_id = tool.tool_id

      lti_adapter = create_lti_adapter(return_url:, lti_launch:, opts: adapter_opts, expander_opts:)
      lti_launch.params = build_jwt_message(lti_adapter, message_type)
      lti_launch.resource_url = lti_adapter.launch_url

      log_launch(
        message_type:,
        launch_type: log_launch_type,
        launch_url: lti_launch.params["target_link_uri"]
      )
      lti_launch
    end

    def build_jwt_message(adapter, message_type)
      case message_type
      when LtiAdvantage::Messages::AssetProcessorSettingsRequest::MESSAGE_TYPE
        adapter.generate_post_payload_for_asset_processor_settings
      when LtiAdvantage::Messages::ReportReviewRequest::MESSAGE_TYPE
        adapter.generate_post_payload_for_report_review
      when LtiAdvantage::Messages::EulaRequest::MESSAGE_TYPE
        adapter.generate_post_payload_for_eula
      else
        raise "Unsupported message type: #{message_type}"
      end
    end

    def create_lti_adapter(return_url:, lti_launch:, opts: {}, expander_opts: {})
      default_opts = {
        domain: HostUrl.context_host(@domain_root_account, request.host)
      }

      Lti::LtiAdvantageAdapter.new(
        tool:,
        user: @current_user,
        context:,
        return_url:,
        expander: create_variable_expander(lti_launch:, expander_opts:),
        include_storage_target: !in_lti_mobile_webview?,
        opts: default_opts.merge(opts)
      )
    end

    def create_variable_expander(lti_launch:, expander_opts: {})
      Lti::VariableExpander.new(
        @domain_root_account,
        context,
        self,
        {
          current_user: @current_user,
          current_pseudonym: @current_pseudonym,
          tool:,
          launch: lti_launch
        }.merge(expander_opts)
      )
    end

    def log_launch(message_type:, launch_type:, launch_url:)
      Lti::LogService.new(
        tool:,
        context:,
        user: @current_user,
        session_id: session[:session_id],
        launch_type:,
        launch_url:,
        message_type:
      ).call
    end

    def require_access_to_context
      if context.is_a?(Account)
        require_user
      elsif !context.grants_right?(@current_user, session, :read)
        render_unauthorized_action
      end
    end

    def require_1_3_tool
      render status: :bad_request, plain: "Only LTI 1.3 tools support this launch" unless tool.use_1_3?
    end
  end
end
