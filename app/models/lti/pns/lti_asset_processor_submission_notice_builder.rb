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
    # This class is responsible for building the LtiAssetProcessorSubmissionNotice notice.
    # This kind of PNS notice is sent by the Lti::AssetProcessorNotifier to an Asset Processor service to notify it of a new submission.
    class LtiAssetProcessorSubmissionNoticeBuilder < NoticeBuilder
      REQUIRED_PARAMS = %i[
        assignment
        asset_report_service_url
        assets
        custom
        for_user_id
        notice_event_timestamp
        submission_lti_id
      ].freeze
      REQUIRED_ASSETS_PARAMS = %i[asset_id url sha256_checksum timestamp size content_type].freeze

      def initialize(params)
        validate_params!(params)
        @params = params
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
      end

      def notice_type
        Lti::Pns::NoticeTypes::ASSET_PROCESSOR_SUBMISSION
      end

      def custom_ims_claims(_tool)
        {
          for_user: {
            user_id: @params[:for_user_id],
          },
          assetreport: {
            scope: [
              TokenScopes::LTI_ASSET_REPORT_SCOPE
            ],
            report_url: @params[:asset_report_service_url]
          },
          assetservice: {
            scope: [
              TokenScopes::LTI_ASSET_READ_ONLY_SCOPE
            ],
            assets: @params[:assets].map { |asset| asset_claim(asset) }
          },
          activity: {
            id: @params[:assignment].lti_context_id,
          },
          submission: {
            id: @params[:submission_lti_id],
          }
        }
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
    end
  end
end
