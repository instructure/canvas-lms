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
#

module Lti::IMS
  # @API Asset Processor
  # @internal
  #
  # 1EdTech Asset Processor services: Eula Service and Eula Acceptance Service.
  #
  class AssetProcessorEulaController < ApplicationController
    before_action :validate_tool_id
    before_action { require_feature_enabled :lti_asset_processor }

    include Concerns::AdvantageServices

    before_action :verify_tool_belongs_to_developer_key

    before_action(
      :validate_user,
      :validate_timestamp,
      only: [:create_acceptance]
    )

    ACTION_SCOPE_MATCHERS = {
      create_acceptance: all_of(TokenScopes::LTI_EULA_USER_SCOPE),
      delete_acceptances: all_of(TokenScopes::LTI_EULA_USER_SCOPE),
      update_tool_eula: all_of(TokenScopes::LTI_EULA_DEPLOYMENT_SCOPE)
    }.with_indifferent_access.freeze

    def validate_tool_id
      render_error("not found", :not_found) unless tool
    end

    def verify_tool_belongs_to_developer_key
      render_error("bad request", :bad_request) unless tool.developer_key_id == developer_key.id
    end

    def validate_user
      render_error("not found", :not_found) unless user&.root_account_ids&.map { |id| Shard.global_id_for(id, user.shard) }&.include?(context.root_account.global_id)
    end

    def validate_timestamp
      unless requested_eula_timestamp
        render_error("A valid ISO8601 timestamp must be provided", :bad_request)
      end
    end

    # @API Update Eula Deployment Configuration
    #
    # Provides a mechanism by which a platform can enable or disable the requirement
    # for users to accept a EULA within the scope of an entire deployment
    #
    # @argument eulaRequired [Boolean]
    #  A boolean value representing whether or not the EULA is required for the deployment.
    #
    # @returns the input arguments as accepted and stored in the database
    # @returns 200 Ok
    #
    # @example_request
    #   {
    #     "eulaRequired": true,
    #   }
    #
    # @example_response
    #   {
    #     "eulaRequired": true,
    #   }
    #
    def update_tool_eula
      tool.update!(asset_processor_eula_required: params.require(:eulaRequired))
      render json: { eulaRequired: tool.asset_processor_eula_required }, status: :ok
    end

    # @API Create an Eula Acceptance
    #
    # The EULA user acceptance service provides a mechanism
    # by which a tool can notify a platform of whether or not a user has accepted a EULA.
    #
    # @argument userId [String]
    #  The userId represents the user who has accepted or declined the EULA,
    #  `lti_id` of the Canvas User.
    #
    # @argument accepted [Boolean]
    #   A boolean value representing whether or not the user has accepted the EULA
    #
    # @argument timestamp [String]
    #   The timestamp represents the time at which the user accepted or declined the EULA.
    #   This timestamp must be formatted as an ISO 8601 date time.
    #
    # @returns the input arguments as accepted and stored in the database
    # @returns 201 Created
    #
    # @example_request
    #   {
    #     "userId": "59ed2101-0302-406c-b53f-9705ae1cb357",
    #     "accepted": true,
    #     "timestamp": "2022-04-16T18:54:36.736+00:00"
    #   }
    #
    # @example_response
    #   {
    #     "userId": "59ed2101-0302-406c-b53f-9705ae1cb357",
    #     "accepted": true,
    #     "timestamp": "2022-04-16T18:54:36.736+00:00"
    #   }
    #
    def create_acceptance
      if user_eulas_scope.where(timestamp: requested_eula_timestamp..).exists?
        render json: { error: "timestamp older than latest" }, status: :conflict
        return
      end
      eula_acceptance = nil
      Lti::AssetProcessorEulaAcceptance.transaction do
        user_eulas_scope.destroy_all
        eula_acceptance = user.lti_asset_processor_eula_acceptances.new(
          context_external_tool_id: tool.id,
          timestamp: requested_eula_timestamp,
          accepted: params.require(:accepted)
        )
        eula_acceptance.save!
      end
      render json: {
               timestamp: eula_acceptance.timestamp,
               accepted: eula_acceptance.accepted,
               userId: user.lti_id
             },
             status: :created
    end

    # @API Delete Eula Acceptances for deployment
    #
    # Remove the EULA acceptance status for all users within the current deployment.
    # This will allow a tool to reset the EULA acceptance status for all users,
    # and force them to accept the EULA again in the case that the EULA has changed.
    #
    # @returns 204 No Content
    #
    def delete_acceptances
      tool.lti_asset_processor_eula_acceptances.destroy_all
      head :no_content
    end

    def tool
      @tool ||= Lti::ToolFinder.find_by(scope: ContextExternalTool.active, id: params.require(:context_external_tool_id))
    end

    def scopes_matcher
      ACTION_SCOPE_MATCHERS.fetch(action_name, self.class.none)
    end

    def context
      tool.context
    end

    def user
      @user ||= User.active.find_by(lti_id: params.require(:userId))
    end

    def requested_eula_timestamp
      @requested_eula_timestamp ||=
        params.require(:timestamp).then do |timestamp|
          Time.zone.iso8601(timestamp)
        rescue ArgumentError
          nil
        end
    end

    def user_eulas_scope
      @user_eulas_scope ||= user.lti_asset_processor_eula_acceptances.active.where(context_external_tool_id: tool.id)
    end
  end
end
