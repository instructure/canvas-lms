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
  # This module is responsible for notifying all relevant Asset Processors of a discussion topic about
  # discussion entry creation, modification, deletion or restoration.
  module AssetProcessorDiscussionNotifier
    extend AssetProcessorNotifierHelper

    module_function

    def notify_asset_processors_of_discussion(current_user:, discussion_entry_versions:, assignment:, contribution_status:, submission: nil, asset_processor: nil, tool_id: nil)
      return if discussion_entry_versions.empty?
      return unless assignment.discussion_topic?
      return unless discussion_entry_versions.first.root_account.feature_enabled?(:lti_asset_processor_discussions)
      return if submission.present? && !submission.asset_processor_for_discussions_compatible?

      asset_processors = assignment.lti_asset_processors
      if asset_processor.present?
        asset_processors = asset_processors.where(id: asset_processor.id)
      end
      if tool_id.present?
        asset_processors = asset_processors.where(context_external_tool_id: tool_id)
      end
      return if asset_processors.empty?

      version_assets = discussion_entry_versions.map do |version|
        assets = create_assets_for_discussion_entry(submission, version)
        assets.each(&:calculate_sha256_checksum!)
        [version, assets]
      end

      asset_processors.each do |ap|
        builders = version_assets.map do |version, assets|
          collaboration_notice_builder(assignment, submission, assets, ap, version, contribution_status, current_user)
        end
        Lti::PlatformNotificationService.notify_tools(cet_id_or_ids: ap.context_external_tool_id, builders:)
      end
    end

    def collaboration_notice_builder(assignment, submission, assets, asset_processor, discussion_entry_version, contribution_status, current_user)
      Pns::LtiAssetProcessorContributionNoticeBuilder.new(
        {
          assignment:,
          asset_report_service_url: assets.any? ? asset_report_service_url(asset_processor) : nil,
          assets: assets.map { |asset| asset_hash(submission, asset, asset_processor) },
          contribution_status:,
          custom: asset_processor.custom || {},
          discussion_entry_version:,
          for_user_id: discussion_entry_version.user.lti_id,
          notice_event_timestamp: Time.now.utc.iso8601,
          # Teacher comments do not belong to a submission; build claim id only when submission exists
          submission_lti_claim_id: submission_claim_id(submission, discussion_entry_version),
          user: current_user,
        }
      )
    end
    private_class_method :collaboration_notice_builder

    def create_assets_for_discussion_entry(submission, discussion_entry_version)
      # Do not create assets if there is no submission (teacher comment)
      return [] unless submission.present?

      text = Lti::Asset.find_or_create_by!(discussion_entry_version:, submission:)
      discussion_entry = discussion_entry_version.discussion_entry
      attachment = discussion_entry.attachment
      if attachment.present?
        attachment_asset = Lti::Asset.find_or_create_by!(attachment:, submission:)
      end
      [text, attachment_asset].compact
    end
    private_class_method :create_assets_for_discussion_entry

    def submission_claim_id(submission, discussion_entry_version)
      return unless submission.present?

      "#{submission.lti_id}:#{discussion_entry_version.id}:#{discussion_entry_version.discussion_entry.attachment_id}"
    end
    private_class_method :submission_claim_id
  end
end
