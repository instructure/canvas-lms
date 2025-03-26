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
    before_action(
      :validate_tool_id,
      :require_feature_enabled
    )

    include Concerns::AdvantageServices

    before_action(
      :verify_tool_belongs_to_developer_key
    )

    def require_feature_enabled
      render_error("not found", :not_found) unless context.root_account.feature_enabled?(:lti_asset_processor)
    end

    def validate_tool_id
      render_error("not found", :not_found) unless tool
    end

    def verify_tool_belongs_to_developer_key
      render_error("bad request", :bad_request) unless tool.developer_key_id == developer_key.id
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

    def tool
      @tool ||= ContextExternalTool.active.find_by(id: params.require(:context_external_tool_id))
    end

    def scopes_matcher
      self.class.all_of(TokenScopes::LTI_EULA_SCOPE)
    end

    def context
      tool.context
    end
  end
end
