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
#

module Lti::IMS
  # @API Asset Processor
  # @internal
  #
  # 1EdTech Asset Processor services: Asset Service and Asset Report Service.
  #
  class AssetProcessorController < ApplicationController
    include Concerns::AdvantageServices
    include AttachmentHelper

    before_action(
      :require_feature_enabled,
      :verify_developer_key_owns_asset_processor
    )

    before_action(
      :verify_valid_report_timestamp,
      :verify_asset_processor_supports_report_type,
      :verify_report_compatible_with_asset,
      :verify_no_newer_report,
      only: :create_report
    )

    before_action(
      :verify_processor_compatible_with_asset,
      only: :lti_asset_show
    )

    ACTION_SCOPE_MATCHERS = {
      create_report: all_of(TokenScopes::LTI_ASSET_REPORT_SCOPE),
      lti_asset_show: all_of(TokenScopes::LTI_ASSET_READ_ONLY_SCOPE)
    }.with_indifferent_access.freeze

    # Recognized params for the asset report create endpoint
    ASSET_REPORT_RECOGNIZED_PARAMS = %i[
      assetId
      comment
      errorCode
      indicationAlt
      indicationColor
      priority
      processingProgress
      scoreGiven
      scoreMaximum
      timestamp
      title
      type
    ].freeze

    # @API Create an Asset Report
    #
    # Creates a report for a given Canvas-managed asset (such as a submission
    # attachment).
    #
    # @argument assetId [String]
    #   The UUID of the asset to which the report applies. Canvas will supply
    #   this to the tool in the the `LtiAssetProcessorSubmissionNotice`.
    #
    # @argument errorCode [Optional, String]
    #   A machine-readable code indicating the cause of the failure, for reports
    #   with a processingProgress value of `Failed`. The following standard error
    #   codes are available, but tools may use their own (in which case the tool
    #   may provide human-readable information in the `comment` field):
    #   UNSUPPORTED_ASSET_TYPE, ASSET_TOO_LARGE, ASSET_TOO_SMALL,
    #   EULA_NOT_ACCEPTED, DOWNLOAD_FAILED
    #
    # @argument indicationAlt [Optional, String]
    #   Alternate text representing the meaning of the indicationColor for screen
    #   readers or as a tooltip over the indication color.
    #
    # @argument indicationColor [Optional, String]
    #   A hex (#RRGGBB) color code the tool wishes to use indicating the outcome
    #   of an asset's report.
    #
    # @argument priority [Integer]
    #   A number from 0 (meaning "good" or "success") to 5 (meaning urgent or
    #   time-critical notable features) indicating the tool's perceived priority
    #   of the report. If a priority is not known or applicable, the tool should
    #   use the value 0.
    #
    # @argument processingProgress [String]
    #   Indicates the status of the report. Must be one of the following:
    #   Processed, Processing, PendingManual, Failed, NotProcessed, NotReady.
    #   If an unrecognized value is given, Canvas will assume `NotReady`.
    #
    # @argument scoreGiven [Optional, Float]
    #   The report's score. Must be greater or equal to zero. Required
    #   if scoreMaximum is provided. scoreGiven may be greater than scoreMaximum.
    #
    # @argument scoreMaximum [Optional, Float]
    #   The denominator in a score value (e.g. total calculated score is
    #   scoreGiven / scoreMaximum). Must be positive. Required if scoreGiven is
    #   provided.
    #
    # @argument timestamp [String]
    #   An ISO8601 date time value with microsecond precision. Reports with newer
    #   timetamps for the same asset and report type supersede
    #   previously submitted reports with older (or equal) timestamps. Likewise,
    #   if the timestamp provided is older than the latest timestamp for an
    #   existing report (of same asset and type), the new report will be
    #   ignored and the endpoint will return an HTTP 409 (Conflict).
    #
    # @argument title [Optional, String]
    #   A human-readable title for the report, to be displayed to the user.
    #
    # @argument type [String]
    #   An opaque value representing the type of report. If the Asset Processor
    #   tool has previously declared a `supportedTypes` list, the type value here
    #   must be one of those types.
    #
    # @returns the input arguments, as accepted and stored in the database.
    # Returns an HTTP 201 (Created) on success.
    #
    # @example_request
    #   {
    #     "assetId" : "57d463ea-6e5d-45c8-a86f-64f3dd9ef81e",
    #     "type": "originality",
    #     "timestamp": "2025-01-24T17:56:53.221+00:00",
    #     "title": "Originality Report",
    #     "scoreGiven" : 75,
    #     "scoreMaximum" : 100,
    #     "indicationColor" : "#EC0000",
    #     "indicationAlt" : "High percentage of matched text.",
    #     "priority": 5,
    #     "processingProgress": "Processed"
    #   }
    #
    # @example_request
    #   {
    #     "assetId" : "57d463ea-6e5d-45c8-a86f-64f3dd9ef81e",
    #     "type": "originality",
    #     "timestamp": "2025-01-24T17:56:53.221+00:00",
    #     "title": "Originality Report",
    #     "priority": 0,
    #     "errorCode": "UNSUPPORTED_ASSET_TYPE",
    #     "processingProgress": "Failed"
    #   }
    #
    # @example_response
    #   {
    #     "assetId" : "57d463ea-6e5d-45c8-a86f-64f3dd9ef81e",
    #     "type": "originality",
    #     "timestamp": "2025-01-24T17:56:53.221+00:00",
    #     "title": "Originality Report",
    #     "scoreGiven" : 75,
    #     "scoreMaximum" : 100,
    #     "indicationColor" : "#EC0000",
    #     "indicationAlt" : "High percentage of matched text.",
    #     "priority": 5,
    #     "processingProgress": "Processed"
    #   }
    #
    def create_report
      timestamp = report_timestamp
      extensions = request.request_parameters.except(*ASSET_REPORT_RECOGNIZED_PARAMS)

      report = Lti::AssetReport.transaction do
        reports_scope.where(timestamp: ..timestamp).destroy_all
        reports_scope.create!(timestamp:, extensions:, **translated_report_model_attrs)
      end

      # Due to a race condition in the above, it's possible two reports exist
      # at this point. Remove all but the 'winning' one (latest timestamp, or
      # latest id if timestamps are equal).
      last_report = reports_scope.active.order(:timestamp, :id).last
      reports_scope.where("timestamp < ? or (timestamp = ? and id < ?)", timestamp, timestamp, last_report.id).destroy_all

      # Even if we just deleted the newly created report, we can tell the client
      # we created the report, as we essentially created it and it was immediately superseded.
      render json: report_to_api_json(report), status: :created
    end

    def lti_asset_show
      render_error("not found", :not_found) unless download_asset&.attachment
      render_or_redirect_to_stored_file(
        attachment: download_asset.attachment
      )
    end

    private

    def report_asset
      @report_asset ||= Lti::Asset.find_by(uuid: params.require(:assetId))
    end

    def download_asset
      @download_asset ||= Lti::Asset.find_by(uuid: params.require(:asset_id))
    end

    def report_type
      params.require(:type)
    end

    def reports_scope
      @reports_scope ||=
        asset_processor.asset_reports.where(asset: report_asset, report_type:)
    end

    def report_timestamp
      @report_timestamp ||=
        params.require(:timestamp).then do |timestamp|
          Time.zone.iso8601(timestamp)
        rescue ArgumentError
          nil
        end
    end

    def translated_report_model_attrs
      input_attrs = params.permit(*ASSET_REPORT_RECOGNIZED_PARAMS)

      input_attrs.except(:assetId, :type, :timestamp).transform_keys do |k|
        k.underscore.to_sym
      end
    end

    def verify_valid_report_timestamp
      unless report_timestamp
        render_error("A valid ISO8601 timestamp must be provided", :bad_request)
      end
    end

    def verify_asset_processor_supports_report_type
      supported = asset_processor.supported_types

      case supported
      when nil
        # Accept all types
      when Array
        unless supported.include?(report_type)
          render_error "Invalid report type, must be one of: #{supported.to_json}", :unprocessable_entity
        end
      else
        render_error "Invalid supportedTypes on asset processor's 'report' object; this processor is broken and cannot accept reports", :bad_request
      end
    end

    def verify_report_compatible_with_asset
      unless report_asset&.compatible_with_processor?(asset_processor)
        render_error "Invalid asset", :bad_request
      end
    end

    def verify_processor_compatible_with_asset
      render_error("not found", :not_found) unless download_asset
      unless download_asset&.compatible_with_processor?(asset_processor)
        render_error "Invalid asset", :bad_request
      end
    end

    def verify_no_newer_report
      if reports_scope.where("timestamp > ?", report_timestamp).exists?
        render_error "An existing report has a newer timestamp", :conflict
      end
    end

    def report_to_api_json(report)
      main_attrs = ASSET_REPORT_RECOGNIZED_PARAMS - %i[assetId type]

      main_attrs.index_with do |k|
        report.attributes[k.to_s.underscore]
      end.compact.merge(
        assetId: report.asset.uuid,
        type: report.report_type
      ).merge(report.extensions || {})
    end

    # Non-action specific methods:

    def asset_processor
      @asset_processor ||= Lti::AssetProcessor.active.find(params[:asset_processor_id].to_i)
    end

    def context
      asset_processor.assignment.context
    end

    def verify_developer_key_owns_asset_processor
      unless asset_processor.context_external_tool.developer_key_id == developer_key.id
        render_error("Asset processor not owned by this developer key", :forbidden)
      end
    end

    def require_feature_enabled
      unless context.root_account.feature_enabled?(:lti_asset_processor)
        render_error("not found", :not_found)
      end
    end

    def scopes_matcher
      ACTION_SCOPE_MATCHERS.fetch(action_name, self.class.none)
    end
  end
end
