# frozen_string_literal: true

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

module Lti
  # @API LTI ContextControls
  #
  # @beta
  # @internal
  #
  # Configure the availability of an LTI Registration in a specific context.
  # Used by the Canvas Apps page UI.
  #
  # @model Lti::ContextControl
  #   {
  #     "id": "Lti::ContextControl",
  #     "description": "Represent availability of an LTI registration in a specific context",
  #     "properties": {
  #         "id": {
  #           "description": "the Canvas ID of the Lti::ContextControl object",
  #           "example": 2,
  #           "type": "integer"
  #         },
  #         "course_id": {
  #           "description": "the Canvas ID of the Course that owns this. one of this or account_id will always be present",
  #           "example": 2,
  #           "type": "integer"
  #         },
  #         "account_id": {
  #           "description": "the Canvas ID of the Account that owns this. one of this or course_id will always be present",
  #           "example": 2,
  #           "type": "integer"
  #         },
  #         "deployment_id": {
  #           "description": "the Canvas ID of the ContextExternalTool that owns this, representing an LTI deployment",
  #           "example": 2,
  #           "type": "integer"
  #         },
  #         "available": {
  #           "description": "The state of this tool in this context. `true` means the tool is available in this context and in all contexts below it.",
  #           "example": true,
  #           "type": "boolean"
  #         },
  #         "path": {
  #           "description": "A representation of the account hierarchy for the context that owns this object. Used for checking availability during LTI operations.",
  #           "example": "a1.a2.c3.",
  #           "type": "string"
  #         },
  #         "display_path": {
  #           "description": "A human-readable representation of the account hierarchy for the context that owns this object. Includes account and course names",
  #           "example": ["Root Account", "Sub Account", "My Course"],
  #           "type": "array",
  #           "items": {
  #             "type": "string"
  #           }
  #         },
  #         "context_name": {
  #           "description": "The name of the context this object is associated with",
  #           "example": "My Course",
  #           "type": "string"
  #         },
  #         "depth": {
  #           "description": "The depth of ContextControls for this particular deployment account chain, which can be different from the number of accounts in the chain. Used for indentation in the Canvas UI.",
  #           "example": 2,
  #           "type": "integer"
  #         },
  #         "workflow_state": {
  #           "description": "The state of the object",
  #           "example": "active",
  #           "type": "string",
  #           "enum": ["active", "deleted"]
  #         },
  #         "created_at": {
  #           "description": "Timestamp of the object's creation",
  #           "example": "2024-01-01T00:00:00Z",
  #           "type": "string"
  #         },
  #         "updated_at": {
  #           "description": "Timestamp of the object's last update",
  #           "example": "2024-01-01T00:00:00Z",
  #           "type": "string"
  #         },
  #         "created_by": {
  #           "description": "The user that created this object. Not always present.",
  #           "example": { "type": "User" },
  #           "type": "User",
  #           "$ref": "User"
  #         },
  #         "updated_by": {
  #           "description": "The user that last updated this object. Not always present.",
  #           "example": { "type": "User" },
  #           "type": "User",
  #           "$ref": "User"
  #         }
  #     }
  #   }
  #
  class ContextControlsController < ApplicationController
    include Api::V1::Lti::Deployment
    include Api::V1::Lti::ContextControl

    before_action :require_user
    before_action :require_feature_flag
    before_action :require_manage_lti_registrations

    # @API List All Context Controls
    #
    # List all LTI ContextControls for the given LTI Registration.
    # These controls are partitioned by LTI Deployment, and have added
    # calculated fields for display in the Canvas UI.
    #
    # This endpoint is used to populate the Availability page for an LTI Registration
    # and may not be useful for general API Usage. For listing all ContextControls
    # for a given Deployment, see the LTI Deployments - List Controls for Deployment endpoint.
    #
    # @returns [Lti::Deployment]
    #
    # @example_request
    #
    #   curl -X GET 'https://<canvas>/api/v1/lti_registrations/<registration_id>/controls' \
    #        -H "Authorization: Bearer <token>"
    def index
      deployment_scope = registration.deployments.active
      if deployment_scope.empty?
        return render json: []
      end

      # sort contexts (and deployments) by account hierarchy, with root account first
      # TODO: controls will be sorted by hierarchy as part of INTEROP-8992,
      # and this can flip: deployments can be pulled from and sorted by controls
      # and this sorting can be removed
      contexts = deployment_scope.preload(:context).map(&:context).uniq.sort_by do |context|
        if context.respond_to?(:parent_account_id)
          # root account first
          context.parent_account_id || 0
        else
          context.account_id
        end
      end

      deployments = deployment_scope.joins(Lti::ContextToolFinder.context_ordering_sql(contexts)).order("context_order.ordering")
      controls_by_deployment = Lti::ContextControl.active.where(deployment: deployments).group_by(&:deployment_id)

      json = deployments.map do |deployment|
        context_controls = controls_by_deployment[deployment.id] || []

        # for now, only get the "root" control, for the context in which the deployment is installed
        # TODO: remove as part of INTEROP-8992
        context_controls = context_controls.select do |cc|
          (cc.account_id == deployment.context_id && deployment.context_type == "Account") ||
            (cc.course_id == deployment.context_id && deployment.context_type == "Course")
        end

        lti_deployment_json(deployment, @current_user, session, context, context_controls:)
      end

      render json:
    rescue => e
      report_error(e)
      raise e
    end

    # @API Show LTI Context Control
    #
    # Display details of the specified LTI ContextControl for the specified LTI registration in this context.
    #
    # @returns Lti::ContextControl
    #
    # @example_request
    #
    #   curl -X GET 'https://<canvas>/api/v1/lti_registrations/<registration_id>/controls/<control_id>' \
    #        -H "Authorization: Bearer <token>"
    def show
      render json: lti_context_control_json(control, @current_user, session, context, include_users: true)
    rescue => e
      report_error(e)
      raise e
    end

    private

    def control
      @control ||= Lti::ContextControl.active.find_by(id: params[:id], registration:)
      raise ActiveRecord::RecordNotFound unless @control

      @control
    end

    def registration
      @registration ||= Lti::Registration.active.find(params[:registration_id])
    end

    def context
      registration.account
    end

    def report_error(exception, code = nil)
      code ||= response_code_for_rescue(exception) if exception
      InstStatsd::Statsd.increment("canvas.lti_context_controls_controller.request_error", tags: { action: action_name, code: })
    end

    def require_manage_lti_registrations
      require_context_with_permission(context, :manage_lti_registrations)
    end

    def require_feature_flag
      unless context.root_account.feature_enabled?(:lti_registrations_next)
        render json: { error: "The specified resource does not exist." }, status: :not_found
      end
    end
  end
end
