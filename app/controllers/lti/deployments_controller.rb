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
  #       "description": "A deployment of an LTI tool in Canvas",
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
  #             "Account"
  #           ]
  #         },
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
  #           "description": "The context controls for this deployment. Only present in the LTI Context Controls - List All Context Controls endpoint.",
  #           "example": [{ "type": "Lti::ContextControl" }],
  #           "type": "array",
  #           "items": { "$ref": "Lti::ContextControl" }
  #         }
  #       }
  #     }
  #
  class DeploymentsController < ApplicationController
    include Api::V1::Lti::Deployment
    include Api::V1::Lti::ContextControl

    before_action :require_account_context
    before_action :require_root_account
    before_action :require_user
    before_action :require_feature_flag
    before_action :require_manage_lti_registrations

    # @API Show LTI Deployment
    #
    # Display details of the specified deployment for the specified LTI registration in this context.
    #
    # @returns Lti::Deployment
    #
    # @example_request
    #
    #   curl -X GET 'https://<canvas>/api/v1/accounts/<account_id>/lti_registrations/<registration_id>/deployments/<deployment_id>' \
    #        -H "Authorization: Bearer <token>"
    def show
      render json: lti_deployment_json(deployment, @current_user, session, @context)
    end

    # @API Create LTI Deployment
    #
    # Create a new deployment for the specified LTI registration for the given context.
    # If no context is specified, the deployment will be created in the root account.
    #
    # @argument for_subaccount_id [Integer] (optional) If provided, the deployment will be created in the specified subaccount.
    # @argument for_course_id [Integer] (optional) If provided, the deployment will be created in the specified course.
    # @argument available [Boolean] (optional) If provided, sets the availability of the created deployment. Defaults to true.
    #
    # @returns Lti::Deployment
    #
    # @example_request
    #
    #   curl -X POST 'https://<canvas>/api/v1/accounts/<account_id>/lti_registrations/<registration_id>/deployments' \
    #        -H "Authorization: Bearer <token>"
    def create
      if params[:for_subaccount_id].present? && params[:for_course_id].present?
        return render json: { error: "Cannot specify both for_subaccount_id and for_course_id" }, status: :unprocessable_entity
      end

      context = if params[:for_subaccount_id].present?
                  Account.find(params[:for_subaccount_id])
                elsif params[:for_course_id].present?
                  Course.find(params[:for_course_id])
                else
                  @context
                end

      unless @context == context || context.root_account_id == @context.id
        return render json: { error: "Context must belong to the current root account" }, status: :not_found
      end

      lti_registration = Lti::Registration.find(params[:registration_id])
      deployment = lti_registration.new_external_tool(context, current_user: @current_user, available: params[:available])

      ContextExternalTool.invalidate_nav_tabs_cache(deployment, @domain_root_account)
      render json: lti_deployment_json(deployment, @current_user, session, @context)
    rescue Lti::ContextExternalToolErrors => e
      render json: e.errors, status: :bad_request, content_type: MIME_TYPE
    end

    # @API Delete LTI Deployment
    #
    # Delete the specified deployment for the specified LTI tool in this context.
    #
    # @returns Lti::Deployment
    #
    # @example_request
    #
    #   curl -X DELETE 'https://<canvas>/api/v1/accounts/<account_id>/lti_registrations/<registration_id>/deployments/<deployment_id>' \
    #        -H "Authorization: Bearer <token>"
    def destroy
      if deployment.destroy
        ContextExternalTool.invalidate_nav_tabs_cache(deployment, @domain_root_account)
        render json: lti_deployment_json(deployment, @current_user, session, @context)
      else
        render json: { error: "Failed to delete LTI deployment" }, status: :internal_server_error
      end
    end

    # @API List LTI Deployments
    #
    # List all deployments available for the specified LTI registration.
    #
    # @returns [Lti::Deployment]
    #
    # @example_request
    #
    #   curl -X GET 'https://<canvas>/api/v1/accounts/<account_id>/lti_registrations/<registration_id>/deployments' \
    #        -H "Authorization: Bearer <token>"
    def list
      lti_registration = Lti::Registration.find(params[:registration_id])
      bookmark = BookmarkedCollection::SimpleBookmarker.new(ContextExternalTool, :id)
      tool_collection = BookmarkedCollection.wrap(bookmark, ContextExternalTool.active.where(lti_registration:))
      tools = Api.paginate(tool_collection, self, api_v1_list_deployments_path)

      render json: tools.map { |tool| lti_deployment_json(tool, @current_user, session, @context) }
    end

    # @API List LTI Context Controls
    #
    # List all context controls for the specified deployment. Context Controls are used to manage
    # LTI tool availability in contexts across Canvas.
    #
    # @returns [Lti::ContextControl]
    #
    # @example_request
    #
    #   curl -X GET 'https://<canvas>/api/v1/accounts/<account_id>/lti_registrations/<registration_id>/deployments/<deployment_id>/controls' \
    #        -H "Authorization: Bearer <token>"
    def list_controls
      per_page = Api.per_page_for(self, default: 100)
      bookmark = BookmarkedCollection::SimpleBookmarker.new(Lti::ContextControl, :id)
      control_collection = BookmarkedCollection.wrap(bookmark, deployment.context_controls.active)
      controls = Api.paginate(control_collection, self, api_v1_list_deployment_controls_path, per_page:)
      calculated_attrs = Lti::ContextControlService.preload_calculated_attrs(controls)

      json = controls.map do |control|
        lti_context_control_json(control, @current_user, session, @context, include_users: true, calculated_attrs: calculated_attrs[control.id])
      end
      render json:
    end

    private

    def deployment
      @deployment ||= ContextExternalTool.find_by(id: params[:id], lti_registration_id: params[:registration_id], root_account_id: @context.id)
      raise ActiveRecord::RecordNotFound unless @deployment

      @deployment
    end

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
  end
end
