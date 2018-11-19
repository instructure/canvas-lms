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
  include Api::V1::ExternalTools

  before_action :require_context, only: [:create]
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
  # @argument developer_key [Object]
  #   JSON representation of the developer key fields
  #   to use when creating the developer key for the
  #   tool configuraiton. Valid fields are: "name",
  #   "email", "notes", "test_cluster_only", "scopes",
  #   "require_scopes".
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
    tool_config = Lti::ToolConfiguration.create_tool_and_key!(account, tool_configuration_params)
    update_developer_key!(tool_config)
    render json: Lti::ToolConfigurationSerializer.new(tool_config)
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
  # @argument developer_key [Object]
  #   JSON representation of the developer key fields
  #   to use when updating the developer key for the
  #   tool configuraiton. Valid fields are: "name",
  #   "email", "notes", "test_cluster_only", "scopes",
  #   "require_scopes".
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
      settings: tool_configuration_params[:settings],
      settings_url: tool_configuration_params[:settings_url],
      disabled_placements: tool_configuration_params[:disabled_placements],
      custom_fields: tool_configuration_params[:custom_fields]
    )
    update_developer_key!(tool_config)

    render json: Lti::ToolConfigurationSerializer.new(tool_config)
  end

  # @API Show Tool configuration
  # Show tool configuration for specified developer key.
  #
  # @returns ToolConfiguration
  def show
    render json: Lti::ToolConfigurationSerializer.new(developer_key.tool_configuration)
  end

  # @API Show Tool configuration
  # Destroy the tool configuration for the specified developer key.
  def destroy
    developer_key.tool_configuration.destroy!
    head :no_content
  end

  private

  def update_developer_key!(tool_config)
    developer_key = tool_config.developer_key
    developer_key.public_jwk = tool_config.settings['public_jwk']
    developer_key.update!(developer_key_params)
  end

  def require_tool_configuration
    return if developer_key.tool_configuration.present?
    head :not_found
  end

  def account
    return @context if params[:action] == 'create'
    developer_key.owner_account
  end

  def require_manage_developer_keys
    authorized_action(account, @current_user, :manage_developer_keys)
  end

  def developer_key
    @_developer_key = DeveloperKey.nondeleted.find(params[:developer_key_id])
  end

  def tool_configuration_params
    params.require(:tool_configuration).permit(:settings_url, :custom_fields, disabled_placements: []).merge(
      {settings: params.require(:tool_configuration)[:settings]&.to_unsafe_h}
    )
  end

  def developer_key_params
    return {} unless params.key? :developer_key
    params.require(:developer_key).permit(:name, :email, :notes, :redirect_uris, :test_cluster_only, :require_scopes, scopes: [])
  end
end
