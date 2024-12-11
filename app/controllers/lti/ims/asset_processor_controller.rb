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
  # TODO full @model doc
  class AssetProcessorController < ApplicationController
    include Concerns::AdvantageServices
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

    private

    def report_asset
      @report_asset ||= Lti::Asset.find_by(uuid: params.require(:assetId))
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
      # TODO: use LTI_ASSET_READ_ONLY_SCOPE if action_name is 'lti_asset_show',
      # when we implement lti_asset_show
      # (or remove this comment if we've implemented it outside of this controller)
      # (see line_items_controller#scopes_matcher)
      self.class.all_of(TokenScopes::LTI_ASSET_REPORT_SCOPE)
    end
  end
end
