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
#           "example": { name: "LTI 1.3 Tool" },
#           "type": "object"
#         }
#     }

class Lti::ToolConfigurationsApiController < ApplicationController
  before_action :require_user
  before_action :require_manage_developer_keys
  before_action :require_tool_configuration, only: [:show, :update, :destroy]

  # @API Create Tool configuration
  # Creates tool configuration with the provided parameters.
  #
  # Settings may be provided directly as JSON through the "settings"
  # parameter or indirectly through the "settings_url" parameter.
  #
  # If both the "settings" and "settings_url" parameters are set,
  # the "settings" parameter will be ignored.
  #
  # Use of this endpoint will create a new developer_key.
  #
  # @argument settings [Object]
  #   JSON representation of the tool configuration
  #
  # @argument settings_url [String]
  #   URL of settings JSON
  #
  # @argument developer_key_id [String]
  #
  #
  # @returns ToolConfiguration
  def create
    tool_config = Lti::ToolConfiguration.create!(
      developer_key: DeveloperKey.create!(account: account),
      settings: tool_configuration_params[:settings],
      settings_url: tool_configuration_params[:settings_url]
    )
    update_public_jwk!(tool_config)
    render json: tool_config
  end

  # @API Update Tool configuration
  # Update tool configuration with the provided parameters.
  #
  # Settings may be provided directly as JSON through the "settings"
  # parameter or indirectly through the "settings_url" parameter.
  #
  # If both the "settings" and "settings_url" parameters are set,
  # the "settings" parameter will be ignored.
  #
  #
  # @argument settings [Object]
  #   JSON representation of the tool configuration
  #
  # @argument settings_url [String]
  #   URL of settings JSON
  #
  # @argument developer_key_id [String]
  #
  #
  # @returns ToolConfiguration
  def update
    tool_config = developer_key.tool_configuration
    tool_config.update!(
      settings: tool_configuration_params[:settings],
      settings_url: tool_configuration_params[:settings_url]
    )
    update_public_jwk!(tool_config)

    render json: tool_config
  end

  # @API Show Tool configuration
  # Show tool configuration for specified developer key.
  #
  # @returns ToolConfiguration
  def show
    render json: developer_key.tool_configuration
  end

  # @API Show Tool configuration
  # Destroy the tool configuration for the specified developer key.
  def destroy
    developer_key.tool_configuration.destroy!
    head :no_content
  end

  private

  def update_public_jwk!(tool_config)
    tool_config.developer_key.update!(public_jwk: tool_config.settings['public_jwk'])
  end

  def require_tool_configuration
    return if developer_key.tool_configuration.present?
    head :not_found
  end

  def account
    return @domain_root_account if params[:action] == 'create'
    developer_key.owner_account
  end

  def require_manage_developer_keys
    authorized_action(account, @current_user, :manage_developer_keys)
  end

  def developer_key
    @_developer_key = DeveloperKey.nondeleted.find(params[:developer_key_id])
  end

  def tool_configuration_params
    params.require(:tool_configuration).permit(:settings_url).merge(
      { settings: params.require(:tool_configuration)[:settings]&.to_unsafe_h }
    )
  end
end
