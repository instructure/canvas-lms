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
  class AssetProcessorLaunchController < ApplicationController
    before_action :require_asset_processor
    before_action :require_context
    before_action :require_feature_enabled
    before_action :require_access_to_context
    before_action :require_asset_report, only: :launch_report
    before_action :validate_report_belongs_to_processor, only: :launch_report

    def launch_settings
      init_launch
      @lti_launch.params = lti_adapter(
        launch_url: tool.url_with_environment_overrides(settings_url)
      ).generate_post_payload_for_asset_processor_settings
      @lti_launch.resource_url = lti_adapter.launch_url
      render Lti::AppUtil.display_template("borderless")
    end

    def launch_report
      init_launch
      @lti_launch.params = lti_adapter(
        asset_report: asset_report,
        launch_url: tool.url_with_environment_overrides(report_url),
        submission_attempt: params[:submission_attempt]
      ).generate_post_payload_for_report_review
      @lti_launch.resource_url = lti_adapter.launch_url
      render Lti::AppUtil.display_template("borderless")
    end

    private

    def init_launch
      @lti_launch = Lti::Launch.new
      @lti_launch.link_text = tool.default_label
      @lti_launch.analytics_id = tool.tool_id
    end

    def lti_adapter(opts = {})
      return @lti_adapter if @lti_adapter

      default_opts = {
        message_type: @launch_type,
        asset_processor:,
        domain: HostUrl.context_host(@domain_root_account, request.host)
      }
      @lti_adapter = Lti::LtiAdvantageAdapter.new(
        tool:,
        user: @current_user,
        context: @context,
        return_url: assignment.direct_link,
        expander: variable_expander,
        include_storage_target: !in_lti_mobile_webview?,
        opts: default_opts.merge(opts)
      )
    end

    def variable_expander
      Lti::VariableExpander.new(@domain_root_account, @context, self, {
                                  assignment: assignment,
                                  current_user: @current_user,
                                  current_pseudonym: @current_pseudonym,
                                  tool: tool,
                                  launch: @lti_launch,
                                })
    end

    def report_url
      asset_processor.report&.dig("url") || tool.launch_url
    end

    def settings_url
      asset_processor.url || tool.launch_url
    end

    def launch_type
      params.require(:launch_type)
    end

    def asset_processor
      @asset_processor ||= Lti::AssetProcessor.find(asset_processor_id)
    end

    def tool
      asset_processor.context_external_tool
    end

    def assignment
      asset_processor.assignment
    end

    def asset_report_id
      params.require(:report_id)
    end

    def asset_report
      @asset_report ||= Lti::AssetReport.find(asset_report_id)
    end

    def asset_processor_id
      params.require(:asset_processor_id)
    end

    def require_asset_processor
      not_found unless asset_processor
    end

    def require_context
      return not_found unless assignment&.context

      @context = assignment.context
    end

    def require_feature_enabled
      not_found unless @context.root_account.feature_enabled?(:lti_asset_processor)
    end

    def require_access_to_context
      if @context.is_a?(Account)
        require_user
      elsif !@context.grants_right?(@current_user, session, :read)
        render_unauthorized_action
      end
    end

    def require_asset_report
      not_found unless asset_report
    end

    def validate_report_belongs_to_processor
      unless asset_report.asset_processor.id == asset_processor.id
        render status: :bad_request, plain: "invalid_request"
      end
    end
  end
end
