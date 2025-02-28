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
  # This module is responsible for notifying all relevant Asset Processors of a new submission.
  module AssetProcessorNotifier
    module_function

    def notify_asset_processors(submission)
      return unless submission.submission_type == "online_upload"
      return unless submission.root_account.feature_enabled?(:lti_asset_processor)

      asset_processors = Lti::AssetProcessor.active
                                            .where(assignment: submission.assignment)
                                            .joins(:context_external_tool)
                                            .merge(ContextExternalTool.active)
      return if asset_processors.empty?

      lti_assets = submission.attachments.map do |attachment|
        Lti::Asset.find_or_create_by(attachment:, submission:)
      end
      return if lti_assets.empty?

      asset_processors.each do |ap|
        params = notice_params(submission, lti_assets, ap)
        builder = Pns::LtiAssetProcessorSubmissionNoticeBuilder.new(params)
        Lti::PlatformNotificationService.notify_tools(cet_id_or_ids: ap.context_external_tool_id, builders: [builder])
      end
    end

    def notice_params(submission, assets, asset_processor)
      {
        assignment: submission.assignment,
        asset_report_service_url: asset_report_service_url(asset_processor),
        assets: assets.map do |asset|
          attachment = asset.attachment
          {
            title: submission.assignment.title,
            size: attachment.size,
            asset_id: asset.uuid,
            url: asset_url(asset_processor, asset),
            sha256_checksum: "todo",
            timestamp: attachment.modified_at.iso8601,
            content_type: attachment.content_type
          }
        end,
        custom: asset_processor.custom || {},
        for_user_id: submission.user.lti_id,
        notice_event_timestamp: Time.now.utc.iso8601,
        submission_lti_id: submission.lti_attempt_id,
        user: submission.user,
      }
    end
    private_class_method :notice_params

    def asset_url(asset_processor, asset)
      Rails.application.routes.url_helpers.lti_asset_processor_asset_show_url(
        asset_processor_id: asset_processor.id,
        asset_id: asset.uuid,
        host: asset_processor.root_account.environment_specific_domain
      )
    end
    private_class_method :asset_url

    def asset_report_service_url(asset_processor)
      Rails.application.routes.url_helpers.lti_asset_processor_create_report_url(
        host: asset_processor.root_account.environment_specific_domain,
        asset_processor_id: asset_processor.id
      )
    end
    private_class_method :asset_report_service_url
  end
end
