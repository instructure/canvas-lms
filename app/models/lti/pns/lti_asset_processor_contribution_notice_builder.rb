# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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
  module Pns
    class LtiAssetProcessorContributionNoticeBuilder < NoticeBuilder
      REQUIRED_PARAMS = %i[
        assignment
        assets
        contribution_status
        custom
        for_user_id
        notice_event_timestamp
        discussion_entry_version
      ].freeze
      REQUIRED_ASSETS_PARAMS = %i[asset_id url sha256_checksum timestamp size content_type].freeze
      DRAFT = "Draft"
      SUBMITTED = "Submitted"
      DELETED = "Deleted"
      HIDDEN = "Hidden"

      VALID_CONTRIBUTION_STATUSES = [
        DRAFT,
        SUBMITTED,
        DELETED,
        HIDDEN
      ].freeze

      def initialize(params)
        validate_params!(params)
        @params = params
        ensure_lti_ids
        super()
      end

      def validate_params!(params)
        REQUIRED_PARAMS.each do |param_name|
          raise ArgumentError, "Missing required parameter: #{param_name}" unless params[param_name]
        end
        params[:assets].each do |asset|
          REQUIRED_ASSETS_PARAMS.each do |asset_param_name|
            raise ArgumentError, "Missing required asset parameter #{asset_param_name}" unless asset[asset_param_name]
          end
        end
        if params[:assets].any? && params[:asset_report_service_url].blank?
          raise ArgumentError, "Missing required parameter: asset_report_service_url when assets are present"
        end
        unless VALID_CONTRIBUTION_STATUSES.include?(params[:contribution_status])
          raise ArgumentError, "Invalid contribution_status: #{params[:contribution_status]}. Must be one of: #{VALID_CONTRIBUTION_STATUSES.join(", ")}"
        end
      end

      def notice_type
        NoticeTypes::ASSET_PROCESSOR_CONTRIBUTION
      end

      def custom_ims_claims(_tool)
        discussion_entry_version = @params[:discussion_entry_version]
        discussion_entry = discussion_entry_version.discussion_entry
        {
          for_user: {
            user_id: @params[:for_user_id],
          },
          assetreport: @params[:asset_report_service_url]&.then do |url|
            {
              scope: [
                TokenScopes::LTI_ASSET_REPORT_SCOPE
              ],
              report_url: url
            }
          end,
          assetservice: {
            scope: [
              TokenScopes::LTI_ASSET_READ_ONLY_SCOPE
            ],
            assets: @params[:assets].map { |asset| asset_claim(asset) }
          },
          activity: {
            id: @params[:assignment].lti_context_id,
          },
          contribution: {
            id: discussion_entry.lti_id,
            parent: discussion_entry.parent_entry&.lti_id,
            created: discussion_entry.created_at.iso8601,
            updated: discussion_entry.updated_at.iso8601,
            status: @params[:contribution_status]
          }.compact,
          # Submission id if present, should be submission.lti_id:discussion_entry_version.id:attachment.id
          # So every modification in the text or attachment (even removal) creates a new lti submission id
          submission: @params[:submission_lti_claim_id]&.then { { id: it } }
        }.compact
      end

      def custom_instructure_claims(_tool)
        {}
      end

      # Use Course as context of the notice. This allows us to send the AGS claims in the notice.
      def custom_context
        @params[:assignment].context
      end

      def asset_claim(asset)
        asset.slice(*REQUIRED_ASSETS_PARAMS, :title, :filename).compact
      end

      def notice_event_timestamp
        @params[:notice_event_timestamp]
      end

      def user
        @params[:user]
      end

      def opts
        { extra_claims: %i[roles eulaservice], custom_params: @params[:custom] }
      end

      def expander_opts
        {
          assignment: @params[:assignment]
        }
      end

      def info_log(tool)
        discussion_entry_version = @params[:discussion_entry_version]
        super.merge(
          assignment_id: @params[:assignment].id,
          discussion_entry_id: discussion_entry_version.discussion_entry_id,
          contribution_status: @params[:contribution_status],
          asset_count: @params[:assets].length,
          asset_uuids: @params[:assets].pluck(:asset_id)
        )
      end

      private

      def ensure_lti_ids
        entry = @params[:discussion_entry_version].discussion_entry
        ensure_lti_id!(entry)
        ensure_lti_id!(entry.parent_entry) if entry.parent_entry
      end

      def ensure_lti_id!(discussion_entry)
        return unless discussion_entry.lti_id.blank?

        new_id = SecureRandom.uuid
        updated = DiscussionEntry
                  .where(id: discussion_entry.id)
                  .where(lti_id: nil)
                  .update_all(lti_id: new_id)
        discussion_entry.reload if updated == 1
      end
    end
  end
end
