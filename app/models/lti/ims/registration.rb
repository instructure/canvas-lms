# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

class Lti::IMS::Registration < ApplicationRecord
  CANVAS_EXTENSION_LABEL = "canvas.instructure.com"
  self.table_name = "lti_ims_registrations"

  REQUIRED_GRANT_TYPES = ["client_credentials", "implicit"].freeze
  REQUIRED_RESPONSE_TYPES = ["id_token"].freeze
  REQUIRED_APPLICATION_TYPE = "web"
  REQUIRED_TOKEN_ENDPOINT_AUTH_METHOD = "private_key_jwt"

  validates :application_type,
            :grant_types,
            :response_types,
            :redirect_uris,
            :initiate_login_uri,
            :client_name,
            :jwks_uri,
            :token_endpoint_auth_method,
            :lti_tool_configuration,
            :developer_key,
            presence: true

  validate :required_values_are_present,
           :redirect_uris_contains_uris,
           :lti_tool_configuration_is_valid,
           :scopes_are_valid

  validates :initiate_login_uri,
            :jwks_uri,
            :logo_uri,
            :client_uri,
            :tos_uri,
            :policy_uri,
            format: { with: URI::DEFAULT_PARSER.make_regexp(["http", "https"]) },
            allow_blank: true

  belongs_to :developer_key, inverse_of: :lti_registration

  def settings
    canvas_configuration
  end

  def configuration
    canvas_configuration
  end

  # A Registration (this class) denotes a registration of a tool with a platform. This
  # follows the IMS Dynamic Registration specification. A "Tool Configuration" is
  # Canvas' proprietary representation of a tool's configuration, which predates
  # the dynamic registration specification. This method converts an ims registration
  # into the Canvas proprietary configuration format.
  def canvas_configuration
    config = lti_tool_configuration

    overlay = registration_overlay

    {
      title: client_name,
      scopes: scopes.reject { |s| overlay["disabledScopes"]&.include?(s) || false },
      public_jwk_url: jwks_uri,
      description: config["description"],
      custom_parameters: config["custom_parameters"],
      target_link_uri: config["target_link_uri"],
      oidc_initiation_url: initiate_login_uri,
      url: config["target_link_uri"],
      privacy_level:,
      extensions: [{
        domain: config["domain"],
        platform: "canvas.instructure.com",
        tool_id: client_name,
        privacy_level: "public",
        settings: {
          text: client_name,
          icon_url: config["icon_uri"],
          platform: "canvas.instructure.com",
          placements:
        }
      }]
    }.with_indifferent_access
  end

  def importable_configuration
    configuration&.merge(canvas_extensions)&.merge(configuration_to_cet_settings_map)
  end

  def configuration_to_cet_settings_map
    { url: configuration["target_link_uri"], lti_version: "1.3" }
  end

  def privacy_level
    registration_overlay["privacy_level"] || lti_tool_configuration["https://#{CANVAS_EXTENSION_LABEL}/lti/privacy_level"] || "anonymous"
  end

  def update_external_tools?
    saved_change_to_lti_tool_configuration? || saved_change_to_logo_uri? || saved_change_to_client_name?
  end

  delegate :update_external_tools!, to: :developer_key

  def placements
    lti_tool_configuration["messages"].map do |message|
      if message["placements"].nil?
        []
      else
        message["placements"].map do |placement|
          display_type = message["https://#{CANVAS_EXTENSION_LABEL}/lti/display_type"]
          window_target = nil
          if display_type == "new_window"
            display_type = "default"
            window_target = "_blank"
          end

          placement_name = canvas_placement_name(placement)
          placement_overlay = lookup_placement_overlay(placement) || {}
          {
            placement: placement_name,
            enabled: !placement_disabled?(placement),
            message_type: message["type"],
            target_link_uri: message["target_link_uri"],
            text: placement_overlay["label"] || message["label"],
            icon_url: placement_overlay["icon_url"] || message["icon_uri"],
            custom_fields: message["custom_parameters"],
            display_type:,
            windowTarget: window_target,
          }.merge(width_and_height_settings(message, placement_name)).compact
        end
      end
    end.flatten
  end

  def lookup_placement_overlay(placement_type)
    registration_overlay["placements"]&.find { |p| p["type"] == placement_type }
  end

  def placement_disabled?(placement_type)
    registration_overlay["disabledPlacements"]&.include?(placement_type) || false
  end

  def canvas_extensions
    return {} if configuration.blank?

    extension = configuration["extensions"]&.find { |e| e["platform"] == CANVAS_EXTENSION_LABEL }&.deep_dup || { "settings" => {} }
    # remove any placements at the root level
    extension["settings"].delete_if { |p| Lti::ResourcePlacement::PLACEMENTS.include?(p.to_sym) }
    # read valid placements to root settings hash
    extension["settings"].fetch("placements", []).each do |p|
      extension["settings"][p["placement"]] = p
    end
    extension
  end

  def new_external_tool(context, existing_tool: nil)
    # disabled tools should stay disabled while getting updated
    # deleted tools are never updated during a dev key update so can be safely ignored
    tool_is_disabled = existing_tool&.workflow_state == ContextExternalTool::DISABLED_STATE

    tool = existing_tool || ContextExternalTool.new(context:)
    Importers::ContextExternalToolImporter.import_from_migration(
      importable_configuration,
      context,
      nil,
      tool,
      false
    )
    tool.developer_key = developer_key
    tool.workflow_state = (tool_is_disabled && ContextExternalTool::DISABLED_STATE) || privacy_level || DEFAULT_PRIVACY_LEVEL
    tool.use_1_3 = true
    tool
  end

  def as_json(options = {})
    {
      id: global_id.to_s,
      developer_key_id: developer_key.global_id.to_s,
      overlay: registration_overlay,
      lti_tool_configuration:,
      application_type:,
      grant_types:,
      response_types:,
      redirect_uris:,
      initiate_login_uri:,
      client_name:,
      jwks_uri:,
      logo_uri:,
      token_endpoint_auth_method:,
      contacts:,
      client_uri:,
      policy_uri:,
      tos_uri:,
      scopes:,
      created_at:,
      updated_at:,
      guid:,
    }.as_json(options)
  end

  private

  def required_values_are_present
    if (REQUIRED_GRANT_TYPES - grant_types).present?
      errors.add(:grant_types, "Must include #{REQUIRED_GRANT_TYPES.join(", ")}")
    end
    if (REQUIRED_RESPONSE_TYPES - response_types).present?
      errors.add(:response_types, "Must include #{REQUIRED_RESPONSE_TYPES.join(", ")}")
    end

    if token_endpoint_auth_method != REQUIRED_TOKEN_ENDPOINT_AUTH_METHOD
      errors.add(:token_endpoint_auth_method, "Must be 'private_key_jwt'")
    end

    if application_type != REQUIRED_APPLICATION_TYPE
      errors.add(:application_type, "Must be 'web'")
    end
  end

  def redirect_uris_contains_uris
    return if redirect_uris.all? { |uri| uri.match? URI::DEFAULT_PARSER.make_regexp(["http", "https"]) }

    errors.add(:redirect_uris, "Must only contain valid URIs")
  end

  def scopes_are_valid
    invalid_scopes = scopes - TokenScopes::LTI_SCOPES.keys
    return if invalid_scopes.empty?

    errors.add(:scopes, "Invalid scopes: #{invalid_scopes.join(", ")}")
  end

  def lti_tool_configuration_is_valid
    config_errors = Schemas::Lti::IMS::LtiToolConfiguration.simple_validation_errors(
      lti_tool_configuration,
      error_format: :hash
    )
    return if config_errors.blank?

    errors.add(
      :lti_tool_configuration,
      # Convert errors represented as a Hash to JSON
      config_errors.is_a?(Hash) ? config_errors.to_json : config_errors
    )
  end

  def canvas_placement_name(placement)
    # IMS placement names that have different names in Canvas
    return "link_selection" if placement == "ContentArea"
    return "editor_button" if placement == "RichTextEditor"

    # Otherwise, remove our URL prefix from the Canvas-specific placements
    canvas_extension = "https://#{CANVAS_EXTENSION_LABEL}/lti/"
    placement.start_with?(canvas_extension) ? placement.sub(canvas_extension, "") : placement
  end

  def width_and_height_settings(message, placement)
    keys = ["selection_width", "selection_height"]
    # placements that use launch_width and launch_height
    # instead of selection_width and selection_height
    uses_launch_width = ["assignment_edit", "post_grades"]
    keys = ["launch_width", "launch_height"] if uses_launch_width.include?(placement)

    values = [
      message["https://#{CANVAS_EXTENSION_LABEL}/lti/launch_width"]&.to_i,
      message["https://#{CANVAS_EXTENSION_LABEL}/lti/launch_height"]&.to_i,
    ]

    {
      keys[0].to_sym => values[0],
      keys[1].to_sym => values[1],
    }
  end
end
