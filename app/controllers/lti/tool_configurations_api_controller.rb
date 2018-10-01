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

  before_action :require_context, only: [:create_context_external_tool, :create]
  before_action :require_user
  before_action :require_manage_developer_keys
  before_action :require_tool_configuration, only: [:show, :update, :destroy, :create_context_external_tool]

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
  # @returns ToolConfiguration
  def create
    tool_config = Lti::ToolConfiguration.create!(
      developer_key: DeveloperKey.create!(account: account),
      settings: tool_configuration_params[:settings],
      settings_url: tool_configuration_params[:settings_url]
    )
    update_developer_key!(tool_config)
    render json: tool_config
  end

  # @API Create Tool configuration
  # Creates context_external_tool from attached tool_configuration of
  # the provided developer_key if not already present in context.
  # DeveloperKey must have a ToolConfiguration to create tool or 404 will be raised.
  # Will return an existing ContextExternalTool if one already exists.
  #
  # @argument account_id [String]
  #    if account
  #
  # @argument course_id [String]
  #    if course
  #
  # @argument developer_key_id [String]
  #
  # @returns ContextExternalTool
  def create_context_external_tool
    cet = fetch_existing_tool_in_context_chain
    if cet.nil?
      cet = developer_key.tool_configuration.new_external_tool(@context)
      cet.save!
    end
    render json: external_tool_json(cet, @context, @current_user, session)
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
  # @returns ToolConfiguration
  def update
    tool_config = developer_key.tool_configuration
    tool_config.update!(
      settings: tool_configuration_params[:settings],
      settings_url: tool_configuration_params[:settings_url]
    )
    update_developer_key!(tool_config)

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

  def require_create_external_tool
    authorized_action(@context, @current_user, :create_tool_manually)
  end

  def developer_key
    @_developer_key = DeveloperKey.nondeleted.find(params[:developer_key_id])
  end

  def fetch_existing_tool_in_context_chain
    ContextExternalTool.all_tools_for(@context).where(developer_key: developer_key).take
  end

  def tool_configuration_params
    params.require(:tool_configuration).permit(:settings_url).merge(
      { settings: params.require(:tool_configuration)[:settings]&.to_unsafe_h }
    )
  end

  def developer_key_params
    return {} unless params.key? :developer_key
    params.require(:developer_key).permit(:name, :email, :notes, :test_cluster_only, :require_scopes, scopes: [])
  end
end
