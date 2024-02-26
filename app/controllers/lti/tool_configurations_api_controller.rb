# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

# @API Tool Configuration API
# @internal
# @model ToolConfiguration
#     {
#       "id": "ToolConfiguration",
#       "description": "A tool configuration associated with a developer key",
#       "properties": {
#         "developer_key_id": {
#           "description": "The tool configuration's developer key id",
#           "example": 23,
#           "type": "integer"
#         },
#         "settings": {
#           "description": "The tool configuration JSON",
#           "example": { "name": "LTI 1.3 Tool" },
#           "type": "object"
#         }
#       }
#     }

class Lti::ToolConfigurationsApiController < ApplicationController
  include Api::V1::ExternalTools

  before_action :require_context, only: [:create, :show]
  before_action :require_user
  before_action :require_manage_developer_keys, except: :show
  before_action :require_key_in_context, only: :show
  before_action :require_manage_lti, only: :show
  before_action :require_tool_configuration, only: %i[show update destroy]

  # @API Create Tool configuration
  # Creates tool configuration with the provided parameters.
  #
  # Settings may be provided directly as JSON through the "settings"
  # parameter or indirectly through the "settings_url" parameter.
  #
  # If both the "settings" and "settings_url" parameters are set,
  # the "settings_url" parameter will be ignored.
  #
  # When "settings_url" parameter is set, the DeveloperKey.redirect_uris will
  # be created with "target_link_uri" from the JSON tool configuration, in case,
  # the developer_key.redirect_uris parameter is not given.
  #
  # Use of this endpoint will create a new developer_key.
  #
  # @argument settings [Object]
  #   JSON representation of the tool configuration
  #
  # @argument settings_url [String]
  #   URL of settings JSON
  #
  # @argument developer_key [Object]
  #   JSON representation of the developer key fields
  #   to use when creating the developer key for the
  #   tool configuraiton. Valid fields are: "name",
  #   "email", "notes", "test_cluster_only",
  #   "client_credentials_audience", "scopes".
  #
  # @argument disabled_placements [Array]
  #   An array of strings indicating which Canvas
  #   placements should be excluded from the
  #   tool configuration.
  #
  # @argument custom_fields [String]
  #   A new line seperated string of key/value pairs
  #   to be used as custom fields in the LTI launch.
  #   Example: foo=bar\ncourse=$Canvas.course.id
  #
  # @returns ToolConfiguration
  def create
    developer_key_redirect_uris
    tool_config = Lti::ToolConfiguration.create_tool_config_and_key!(account, tool_configuration_params)
    update_developer_key!(tool_config, developer_key_redirect_uris)
    render json: Lti::ToolConfigurationSerializer.new(tool_config, include_warnings: true)
  end

  # @API Update Tool configuration
  # Update tool configuration with the provided parameters.
  #
  # Settings may be provided directly as JSON through the "settings"
  # parameter. The settings_url is not used for updates.
  #
  # If both the "settings" and "settings_url" parameters are set,
  # the "settings" parameter will be ignored.
  #
  #
  # @argument settings [Object]
  #   JSON representation of the tool configuration
  #
  # @argument developer_key_id [String]
  #
  # @argument developer_key [Object]
  #   JSON representation of the developer key fields
  #   to use when updating the developer key for the
  #   tool configuraiton. Valid fields are: "name",
  #   "email", "notes", "test_cluster_only",
  #   "client_credentials_audience", "scopes".
  #
  # @argument disabled_placements [Array]
  #   An array of strings indicating which Canvas
  #   placements should be excluded from the
  #   tool configuration.
  # @argument custom_fields [String]
  #   A new line seperated string of key/value pairs
  #   to be used as custom fields in the LTI launch.
  #   Example: foo=bar\ncourse=$Canvas.course.id
  #
  # @returns ToolConfiguration
  def update
    tool_config = developer_key.tool_configuration
    tool_config.update!(
      settings: tool_configuration_params[:settings]&.to_unsafe_hash&.deep_merge(manual_custom_fields),
      disabled_placements: tool_configuration_params[:disabled_placements],
      privacy_level: tool_configuration_params[:privacy_level]
    )
    update_developer_key!(tool_config)

    render json: Lti::ToolConfigurationSerializer.new(tool_config, include_warnings: true)
  end

  # @API Show Tool configuration
  # Show tool configuration for specified developer key.
  #
  # @returns ToolConfiguration
  def show
    if developer_key.lti_registration.present?
      render json: ({
        tool_configuration: {
          settings: developer_key.lti_registration.canvas_configuration
        }
      })
    else
      render json: Lti::ToolConfigurationSerializer.new(developer_key.tool_configuration)
    end
  end

  # @API Show Tool configuration
  # Destroy the tool configuration for the specified developer key.
  def destroy
    developer_key.tool_configuration.destroy!
    head :no_content
  end

  private

  def require_key_in_context
    head :unauthorized unless developer_key.usable_in_context?(@context)
  end

  def require_manage_lti
    head :unauthorized unless @context.grants_any_right?(@current_user, :lti_add_edit, *RoleOverride::GRANULAR_MANAGE_LTI_PERMISSIONS)
  end

  def manual_custom_fields
    {
      custom_fields: ContextExternalTool.find_custom_fields_from_string(tool_configuration_params[:custom_fields])
    }.stringify_keys
  end

  def update_developer_key!(tool_config, redirect_uris = nil)
    developer_key = tool_config.developer_key
    developer_key.redirect_uris = redirect_uris unless redirect_uris.nil?
    developer_key.public_jwk = tool_config.settings["public_jwk"]
    developer_key.public_jwk_url = tool_config.settings["public_jwk_url"]
    developer_key.oidc_initiation_url = tool_config.settings["oidc_initiation_url"]
    developer_key.is_lti_key = true
    developer_key.update!(developer_key_params)
  end

  def require_tool_configuration
    return if developer_key.tool_configuration.present?

    head :not_found
  end

  def account
    return @context if params[:action] == "create"

    developer_key.owner_account
  end

  def require_manage_developer_keys
    authorized_action(account, @current_user, :manage_developer_keys)
  end

  def developer_key
    @_developer_key = DeveloperKey.nondeleted.find(params[:developer_key_id])
  end

  def tool_configuration_params
    params.require(:tool_configuration).permit(:settings_url, :custom_fields, :privacy_level, disabled_placements: []).merge(
      { settings: params.require(:tool_configuration)[:settings]&.to_unsafe_h }
    )
  end

  def developer_key_params
    return {} if params[:developer_key].blank?

    params.require(:developer_key).permit(:name, :email, :notes, :redirect_uris, :test_cluster_only, :client_credentials_audience, scopes: [])
  end

  def developer_key_redirect_uris
    # When settings_url is set, the redirect_uris parameter is not required.
    # We can infer the redirect_uris from the tool configuration (target_link_uri).
    if tool_configuration_params[:settings_url].present?
      params.dig(:developer_key, :redirect_uris)
    else
      params.require(:developer_key).require(:redirect_uris)
    end
  end
end
