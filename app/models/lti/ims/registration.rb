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
  include Canvas::SoftDeletable
  extend RootAccountResolver
  self.table_name = "lti_ims_registrations"

  REQUIRED_GRANT_TYPES = ["client_credentials", "implicit"].freeze
  REQUIRED_RESPONSE_TYPES = ["id_token"].freeze
  REQUIRED_APPLICATION_TYPE = "web"
  REQUIRED_TOKEN_ENDPOINT_AUTH_METHOD = "private_key_jwt"
  PLACEMENT_VISIBILITY_OPTIONS = %(admins members public)

  CANVAS_EXTENSION_LABEL = "canvas.instructure.com"
  CANVAS_EXTENSION_PREFIX = "https://#{CANVAS_EXTENSION_LABEL}/lti".freeze
  COURSE_NAV_DEFAULT_ENABLED_EXTENSION = "#{CANVAS_EXTENSION_PREFIX}/course_navigation/default_enabled".freeze
  PLACEMENT_VISIBILITY_EXTENSION = "#{CANVAS_EXTENSION_PREFIX}/visibility".freeze
  DISPLAY_TYPE_EXTENSION = "#{CANVAS_EXTENSION_PREFIX}/display_type".freeze
  PRIVACY_LEVEL_EXTENSION = "#{CANVAS_EXTENSION_PREFIX}/privacy_level".freeze
  LAUNCH_WIDTH_EXTENSION = "#{CANVAS_EXTENSION_PREFIX}/launch_width".freeze
  LAUNCH_HEIGHT_EXTENSION = "#{CANVAS_EXTENSION_PREFIX}/launch_height".freeze
  TOOL_ID_EXTENSION = "#{CANVAS_EXTENSION_PREFIX}/tool_id".freeze

  self.ignored_columns += %i[application_type grant_types response_types token_endpoint_auth_method]

  validates :redirect_uris,
            :initiate_login_uri,
            :client_name,
            :jwks_uri,
            :lti_tool_configuration,
            presence: true

  validate :redirect_uris_contains_uris,
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

  belongs_to :developer_key, inverse_of: :ims_registration, optional: false
  belongs_to :lti_registration, inverse_of: :ims_registration, optional: true, class_name: "Lti::Registration"

  resolves_root_account through: :developer_key

  def settings
    canvas_configuration
  end

  def configuration
    canvas_configuration
  end

  # An IMS::Registration (this class) denotes a registration of a tool with a platform. This
  # follows the IMS Dynamic Registration specification. A "Tool Configuration" is
  # Canvas' proprietary representation of a tool's configuration, which predates
  # the dynamic registration specification. This method converts an ims registration
  # into the Canvas proprietary configuration format.
  def canvas_configuration(apply_overlay: true)
    config = lti_tool_configuration

    {
      title: client_name,
      scopes: overlaid_scopes(apply_overlay:),
      public_jwk_url: jwks_uri,
      description: config["description"],
      custom_fields: config["custom_parameters"],
      target_link_uri: config["target_link_uri"],
      oidc_initiation_url: initiate_login_uri,
      url: config["target_link_uri"],
      privacy_level:,
      extensions: [{
        domain: config["domain"],
        platform: "canvas.instructure.com",
        tool_id:,
        privacy_level:,
        settings: {
          text: client_name,
          icon_url: logo_uri,
          platform: "canvas.instructure.com",
          placements: placements(apply_overlay:)
        }
      }]
    }.with_indifferent_access
  end

  # This method converts an IMS Registration into a "Tool Configuration V2",
  # the flattened and standardized version of the Canvas proprietary configuration
  # format meant for internal use with LTI Registrations.
  def registration_configuration
    config = lti_tool_configuration

    {
      name: client_name,
      description: config["description"],
      domain: config["domain"],
      custom_fields: config["custom_parameters"],
      target_link_uri: config["target_link_uri"],
      privacy_level:,
      icon_url: logo_uri,
      oidc_initiation_url: initiate_login_uri,
      redirect_uris:,
      public_jwk_url: jwks_uri,
      scopes: overlaid_scopes,
      placements:,
      tool_id:
    }.with_indifferent_access
  end

  def importable_configuration
    configuration&.merge(canvas_extensions)&.merge(configuration_to_cet_settings_map)
  end

  def configuration_to_cet_settings_map
    { url: configuration["target_link_uri"], lti_version: "1.3", unified_tool_id: }
  end

  def privacy_level
    claims = lti_tool_configuration["claims"] || []
    infered_privacy_level = infer_privacy_level_from(claims)
    registration_overlay["privacy_level"] || lti_tool_configuration[PRIVACY_LEVEL_EXTENSION] || infered_privacy_level
  end

  def overlaid_scopes(apply_overlay: true)
    return scopes unless apply_overlay

    scopes.reject { |s| registration_overlay["disabledScopes"]&.include?(s) || false }
  end

  def update_external_tools?
    saved_change_to_lti_tool_configuration? || saved_change_to_logo_uri? || saved_change_to_client_name?
  end

  delegate :update_external_tools!, to: :developer_key

  def placements(apply_overlay: true)
    lti_tool_configuration["messages"].map do |message|
      if message["placements"].blank?
        # default to link_selection if no placements are specified
        [build_placement_for("link_selection", message)]
      else
        message["placements"].flat_map do |placement|
          build_placement_for(placement, message, apply_overlay:)
        end
      end
    end.flatten.uniq { |p| p[:placement] }
  end

  # Builds a placement object for a given message and placement type
  # returns a list with one item, or an empty list if the placement
  # type is not supported by Canvas
  def build_placement_for(placement_type, message, apply_overlay: true)
    placement_name = canvas_placement_name(placement_type)

    # Return no placement if the placement type is not supported by Canvas
    unless Lti::ResourcePlacement::PLACEMENTS.include?(placement_name.to_sym)
      return []
    end

    display_type = message[DISPLAY_TYPE_EXTENSION]
    window_target = nil
    if display_type == "new_window"
      display_type = "default"
      window_target = "_blank"
    end

    placement_overlay = lookup_placement_overlay(placement_type) || {}

    text = apply_overlay ? (placement_overlay["label"] || message["label"]) : message["label"]
    icon_url = apply_overlay ? (placement_overlay["icon_url"] || message["icon_uri"]) : message["icon_uri"]
    enabled = apply_overlay ? !placement_disabled?(placement_type) : true
    default = if apply_overlay && placement_name == "course_navigation"
                # The placement overlay stores everything in the Canvas proprietary format, in which
                # default is either 'enabled' or 'disabled', so we can fetch the
                # default value directly from the overlay
                placement_overlay["default"] || fetch_default_enabled_setting(message, placement_name)
              else
                fetch_default_enabled_setting(message, placement_name)
              end

    [
      {
        placement: placement_name,
        enabled:,
        message_type: message["type"],
        target_link_uri: message["target_link_uri"],
        text:,
        icon_url:,
        custom_fields: message["custom_parameters"],
        display_type:,
        windowTarget: window_target,
        default:,
        visibility: placement_visibility(message),
      }.merge(width_and_height_settings(message, placement_name)).compact
    ]
  end

  def placement_visibility(message)
    availability = message[PLACEMENT_VISIBILITY_EXTENSION]
    if availability
      PLACEMENT_VISIBILITY_OPTIONS.include?(availability) ? availability : nil
    else
      nil
    end
  end

  # This supports a very old parameter (hence the obtuse name) that *only* applies to the course navigation placement. It hides the
  # tool from the course navigation by default. Teachers can still add the tool to the course navigation using the course
  # settings page if they'd like. The IMS Message stores this value as a boolean, but the Canvas config expects a string
  # value of "enabled" or "disabled" (nil/not present is equivalent to "enabled").
  def fetch_default_enabled_setting(message, placement_name)
    (message[COURSE_NAV_DEFAULT_ENABLED_EXTENSION] == false && placement_name == "course_navigation") ? "disabled" : nil
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
      lti_registration_id: Shard.global_id_for(lti_registration_id).to_s,
      developer_key_id: Shard.global_id_for(developer_key_id).to_s,
      overlay: registration_overlay,
      lti_tool_configuration:,
      application_type: REQUIRED_APPLICATION_TYPE,
      grant_types: REQUIRED_GRANT_TYPES,
      response_types: REQUIRED_RESPONSE_TYPES,
      redirect_uris:,
      initiate_login_uri:,
      client_name:,
      jwks_uri:,
      logo_uri:,
      token_endpoint_auth_method: REQUIRED_TOKEN_ENDPOINT_AUTH_METHOD,
      contacts:,
      client_uri:,
      policy_uri:,
      tos_uri:,
      scopes:,
      created_at:,
      updated_at:,
      guid:,
      tool_configuration: canvas_configuration,
      default_configuration: canvas_configuration(apply_overlay: false)
    }.as_json(options)
  end

  private

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
    canvas_extension = CANVAS_EXTENSION_PREFIX + "/"
    placement.start_with?(canvas_extension) ? placement.sub(canvas_extension, "") : placement
  end

  def width_and_height_settings(message, placement)
    keys = ["selection_width", "selection_height"]
    # placements that use launch_width and launch_height
    # instead of selection_width and selection_height
    uses_launch_width = ["assignment_edit", "post_grades"]
    keys = ["launch_width", "launch_height"] if uses_launch_width.include?(placement)

    values = [
      message[LAUNCH_WIDTH_EXTENSION]&.to_i,
      message[LAUNCH_HEIGHT_EXTENSION]&.to_i,
    ]

    {
      keys[0].to_sym => values[0],
      keys[1].to_sym => values[1],
    }
  end

  def infer_privacy_level_from(claims)
    has_picture = claims.include?("picture")
    has_name = claims.include?("name") || claims.include?("given_name") || claims.include?("family_name") || claims.include?("https://purl.imsglobal.org/spec/lti/claim/lis")
    has_email = claims.include?("email")

    if has_picture || (has_name && has_email)
      "public"
    elsif has_name && !has_email
      "name_only"
    elsif has_email
      "email_only"
    else
      "anonymous"
    end
  end

  def tool_id
    lti_tool_configuration[TOOL_ID_EXTENSION]
  end
end
