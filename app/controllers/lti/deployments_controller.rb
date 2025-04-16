# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
  # @API LTI Deployments
  #
  # @beta
  # @internal
  #
  #
  # @model Lti::Deployment
  #     {
  #       "id": "Lti::Deployment",
  #       "description": "A registration of an LTI tool in Canvas",
  #       "properties": {
  #         "id": {
  #           "description": "the Canvas ID of the Lti::Deployment object",
  #           "example": 2,
  #           "type": "integer"
  #         },
  #         "registration_id": {
  #           "description": "the Canvas ID of the associated Lti::Registration object",
  #           "example": 2,
  #           "type": "integer"
  #         },
  #         "deployment_id": {
  #           "description": "The Deployment ID of this deployment which is shared with launched tools",
  #           "example": "1:a2ea741a5c06bc26b36bf5a1afeba6c0faaae1ee",
  #           "type": "string"
  #         },
  #         "context_id": {
  #           "description": "The Canvas ID of the context this deployment is associated with",
  #           "example": 2,
  #           "type": "integer"
  #         },
  #         "context_type": {
  #           "description": "The type of context this deployment is associated with",
  #           "example": "Course",
  #           "type": "string",
  #           "enum": [
  #             "Course",
  #             "Account",
  #           ],
  #         }
  #         "context_name": {
  #           "description": "The name of the context this deployment is associated with",
  #           "example": "My Course",
  #           "type": "string"
  #         },
  #         "workflow_state": {
  #           "description": "The workflow state of the deployment",
  #           "example": "active",
  #           "type": "string",
  #           "enum": [
  #             "active",
  #             "deleted"
  #           ]
  #         },
  #         "context_controls": {
  #           "description": "The context controls for this deployment",
  #           "type": "array",
  #           "items": {
  #             "type": "Lti::ContextControl",
  #           }
  #         }
  #       }
  #     }
  #
  class DeploymentsController < ApplicationController
    before_action :require_account_context
    before_action :require_root_account
    before_action :require_user
    before_action :require_feature_flag
    before_action :require_manage_lti_registrations

    # @API Create LTI Deployment
    #
    # Create a new deployment for the specified LTI registration in this context.
    #
    # @param [String] account_id The ID of the account to create the deployment in.
    # @param [String] registration_id The ID of the LTI registration to create a deployment for.
    def create
      lti_registration = Lti::Registration.find(params[:registration_id])
      if lti_registration.nil?
        render json: { error: "LTI registration not found" }, status: :not_found, content_type: MIME_TYPE
        return
      end

      deployment = lti_registration.new_external_tool(@context)

      if deployment.save
        ContextExternalTool.invalidate_nav_tabs_cache(deployment, @domain_root_account)
        render json: deployment_json(deployment)
      else
        deployment.destroy if deployment.persisted?
        render json: deployment.errors, status: :bad_request, content_type: MIME_TYPE
      end
    end

    # @API Delete LTI Deployment
    #
    # Delete the specified deployment for the specified LTI tool in this context.
    #
    # @param [String] account_id The ID of the account the deployment lives in.
    # @param [String] registration_id The ID of the LTI tool to delete a deployment for.
    # @param [String] id The ID of the deployment to delete.
    def destroy
      tool = ContextExternalTool.find_by(
        id: params[:id]
      )
      if tool.nil?
        render json: { error: "LTI deployment not found" }, status: :not_found
        return
      end
      if tool.destroy
        ContextExternalTool.invalidate_nav_tabs_cache(tool, @domain_root_account)
        render json: { message: "LTI deployment deleted" }, status: :ok
      else
        render json: { error: "Failed to delete LTI deployment" }, status: :internal_server_error
      end
    end

    # @API List LTI Deployments
    #
    # List all deployments available in this context for the specified LTI registration.
    #
    # @param [String] account_id The ID of the account the registration lives in.
    # @param [String] registration_id The ID of the LTI Registration to delete a deployment for.
    def list
      registration = Lti::Registration.find(params[:registration_id])
      if registration.nil?
        render json: { error: "LTI registration not found" }, status: :not_found, content_type: MIME_TYPE
        return
      end

      tools = ContextExternalTool.where(
        account: @context,
        lti_registration_id: params[:registration_id]
      ).active

      render json: tools.map { |tool| deployment_json(tool) }
    end

    private

    def require_manage_lti_registrations
      require_context_with_permission(@context, :manage_lti_registrations)
    end

    def require_root_account
      raise ActiveRecord::RecordNotFound unless @context.root_account?
    end

    def require_feature_flag
      unless @context.root_account.feature_enabled?(:lti_registrations_next)
        render json: { error: "The specified resource does not exist." }, status: :not_found
      end
    end

    def deployment_json(deployment)
      {
        "id" => deployment.id,
        "registration_id" => deployment.lti_registration_id,
        "context_id" => deployment.context_id,
        "context_type" => deployment.context_type,
        "context_name" => deployment.context.name,
        "workflow_state" => ["deleted", "disabled"].include?(deployment.workflow_state) ? "deleted" : "active",
        "deployment_id" => deployment.deployment_id,
        # TODO: add context_controls when available
        "context_controls" => []
      }
    end
  end
end
