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
    include Lti::LaunchServices

    before_action :require_asset_processor
    before_action :require_context
    before_action { require_feature_enabled :lti_asset_processor }
    before_action :require_access_to_context

    before_action :require_assignment_edit_permission, only: :launch_settings

    before_action :require_asset_report, only: :launch_report
    before_action :validate_report_belongs_to_processor, only: :launch_report
    before_action :require_report_view_permission, only: :launch_report

    def launch_settings
      @lti_launch = create_and_log_launch(
        message_type: LtiAdvantage::Messages::AssetProcessorSettingsRequest::MESSAGE_TYPE,
        return_url: assignment.direct_link,
        adapter_opts: {
          asset_processor:,
          launch_url: settings_url
        },
        expander_opts: {
          assignment:
        },
        log_launch_type: :content_item
      )
      render Lti::AppUtil.display_template("borderless")
    end

    def launch_report
      @lti_launch = create_and_log_launch(
        message_type: LtiAdvantage::Messages::ReportReviewRequest::MESSAGE_TYPE,
        return_url: assignment.direct_link,
        adapter_opts: {
          asset_report:,
          launch_url: report_url,
          submission_attempt: params[:submission_attempt]
        },
        expander_opts: {
          assignment:
        },
        log_launch_type: :content_item
      )
      render Lti::AppUtil.display_template("borderless")
    end

    private

    def report_url
      @report_url ||= asset_processor.report&.dig("url") || tool.launch_url
    end

    def settings_url
      @settings_url ||= asset_processor.url || tool.launch_url
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
      not_found unless assignment&.context
    end

    def context
      @context ||= assignment.context
    end

    def require_asset_report
      not_found unless asset_report
    end

    def validate_report_belongs_to_processor
      unless asset_report.asset_processor.id == asset_processor.id
        render status: :bad_request, plain: "invalid_request"
      end
    end

    def require_assignment_edit_permission
      authorized_action(assignment, @current_user, :update)
    end

    def require_report_view_permission
      render_unauthorized_action unless asset_report.visible_to_user?(@current_user)
    end
  end
end
