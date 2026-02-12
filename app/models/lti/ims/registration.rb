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

  # These attributes are in the spec (config JSON) but not stored in the
  # database because the particular values are required/implied.
  IMPLIED_SPEC_ATTRIBUTES = %w[grant_types response_types application_type token_endpoint_auth_method].freeze
  REQUIRED_GRANT_TYPES = %w[client_credentials implicit].freeze
  REQUIRED_RESPONSE_TYPE = "id_token"
  REQUIRED_APPLICATION_TYPE = "web"
  REQUIRED_TOKEN_ENDPOINT_AUTH_METHOD = "private_key_jwt"

  PLACEMENT_VISIBILITY_OPTIONS = %w[admins members public].freeze

  CANVAS_EXTENSION_LABEL = "canvas.instructure.com"
  CANVAS_EXTENSION_PREFIX = "https://#{CANVAS_EXTENSION_LABEL}/lti".freeze
  COURSE_NAV_DEFAULT_ENABLED_EXTENSION = "#{CANVAS_EXTENSION_PREFIX}/course_navigation/default_enabled".freeze
  PLACEMENT_VISIBILITY_EXTENSION = "#{CANVAS_EXTENSION_PREFIX}/visibility".freeze
  DISPLAY_TYPE_EXTENSION = "#{CANVAS_EXTENSION_PREFIX}/display_type".freeze
  PRIVACY_LEVEL_EXTENSION = "#{CANVAS_EXTENSION_PREFIX}/privacy_level".freeze
  LAUNCH_WIDTH_EXTENSION = "#{CANVAS_EXTENSION_PREFIX}/launch_width".freeze
  LAUNCH_HEIGHT_EXTENSION = "#{CANVAS_EXTENSION_PREFIX}/launch_height".freeze
  TOOL_ID_EXTENSION = "#{CANVAS_EXTENSION_PREFIX}/tool_id".freeze
  VENDOR_EXTENSION = "#{CANVAS_EXTENSION_PREFIX}/vendor".freeze
  CONTENT_MIGRATION_EXTENSION = "#{CANVAS_EXTENSION_PREFIX}/content_migration".freeze
  DISABLE_REINSTALL_EXTENSION = "#{CANVAS_EXTENSION_PREFIX}/disable_reinstall".freeze

  validates :redirect_uris,
            :initiate_login_uri,
            :client_name,
            :jwks_uri,
            :lti_tool_configuration,
            presence: true

  validate :redirect_uris_contains_uris,
           :lti_tool_configuration_is_valid,
           :scopes_are_valid,
           :validate_overlay,
           :target_link_uri_is_uri,
           unless: :deleted?

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

  # An IMS::Registration (this class) denotes a registration of a tool with a platform. This
  # follows the IMS Dynamic Registration specification. A "Tool Configuration" is
  # Canvas' proprietary representation of a tool's configuration, which predates
  # the dynamic registration specification. This method converts an ims registration
  # into the Canvas proprietary configuration format.
  def canvas_configuration
    config = lti_tool_configuration

    {
      title: client_name,
      scopes:,
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
          placements:,
          message_settings:
        }.compact
      }]
    }.with_indifferent_access
  end

  # This method normalizes access to the various fields of an IMS Registration
  # regardless of whether the source is a Hash (parsed JSON from
  # https://www.imsglobal.org/spec/lti-dr/v1p0#openid-configuration-0) or an ActiveRecord
  # instance of this class.
  def self.normalize_lti_ims_config_access(source)
    if source.is_a?(Hash)
      config = source["lti_tool_configuration"]
      {
        config:,
        client_name: source["client_name"],
        initiate_login_uri: source["initiate_login_uri"],
        jwks_uri: source["jwks_uri"],
        scopes: source["scopes"],
        redirect_uris: source["redirect_uris"],
        logo_uri: source["logo_uri"],
        tool_id: config[TOOL_ID_EXTENSION],
        privacy_level: source[PRIVACY_LEVEL_EXTENSION],
        placements: ims_lti_config_to_internal_placement_config(config),
        message_settings: ims_lti_config_to_internal_message_settings(config)
      }.compact.with_indifferent_access
    else
      config = source.lti_tool_configuration
      {
        config:,
        client_name: source.client_name,
        initiate_login_uri: source.initiate_login_uri,
        jwks_uri: source.jwks_uri,
        scopes: source.scopes,
        redirect_uris: source.redirect_uris,
        logo_uri: source.logo_uri,
        tool_id: source.tool_id,
        privacy_level: source.privacy_level,
        placements: source.placements,
        message_settings: source.message_settings
      }.compact.with_indifferent_access
    end
  end

  # This method converts an IMS Tool Registration's json into an
  # "InternalLtiConfiguration." Works for instances of Lti::IMS::Registration
  # or for a Hash (parsed JSON) with the same structure as an instance of
  # Lti::IMS::Registration.
  def self.to_internal_lti_configuration(source)
    normalized = normalize_lti_ims_config_access(source)

    {
      title: normalized[:client_name],
      description: normalized.dig(:config, :description),
      custom_fields: normalized.dig(:config, :custom_parameters),
      target_link_uri: normalized.dig(:config, :target_link_uri),
      oidc_initiation_url: normalized[:initiate_login_uri],
      public_jwk_url: normalized[:jwks_uri],
      scopes: normalized[:scopes],
      redirect_uris: normalized[:redirect_uris],
      domain: normalized.dig(:config, :domain),
      tool_id: normalized[:tool_id],
      privacy_level: normalized[:privacy_level],
      placements: normalized[:placements],
      launch_settings: {
        icon_url: normalized[:logo_uri],
        text: normalized[:client_name],
        content_migration: normalized.dig(:config, CONTENT_MIGRATION_EXTENSION),
        message_settings: normalized[:message_settings],
      }.compact
    }.compact.with_indifferent_access
  end

  def self.ims_lti_config_to_internal_placement_config(lti_tool_configuration)
    messages = lti_tool_configuration["messages"] || []

    messages.map do |message|
      if Lti::ResourcePlacement::PLACEMENTLESS_MESSAGE_TYPES.include?(message["type"])
        [] # Skip placementless messages like EULA - they're handled in message_settings
      elsif message["placements"].blank?
        # default to link_selection if no placements are specified
        [build_placement_for("link_selection", message)]
      else
        message["placements"].flat_map do |placement|
          build_placement_for(placement, message)
        end
      end
    end.flatten.uniq { |p| p[:placement] }
  end

  def self.ims_lti_config_to_internal_message_settings(lti_tool_configuration)
    messages = lti_tool_configuration["messages"] || []

    messages.filter_map do |message|
      if Lti::ResourcePlacement::PLACEMENTLESS_MESSAGE_TYPES.include?(message["type"])
        {
          type: message["type"],
          enabled: true,
          target_link_uri: message["target_link_uri"],
          custom_fields: message["custom_parameters"]
        }.compact
      else
        nil
      end
    end.presence
  end

  # This method converts an IMS Registration into an "InternalLtiConfiguration",
  # the flattened and standardized version of the Canvas proprietary configuration
  # format meant for internal use with LTI Registrations.
  def internal_lti_configuration
    Lti::IMS::Registration.to_internal_lti_configuration(self)
  end

  def privacy_level
    claims = lti_tool_configuration["claims"] || []
    inferred_privacy_level = infer_privacy_level_from(claims)
    lti_tool_configuration[PRIVACY_LEVEL_EXTENSION] || inferred_privacy_level
  end

  def update_external_tools?
    saved_change_to_lti_tool_configuration? || saved_change_to_logo_uri? || saved_change_to_client_name?
  end

  delegate :update_external_tools!, to: :developer_key

  def placements
    self.class.ims_lti_config_to_internal_placement_config(lti_tool_configuration)
  end

  # Builds a placement object for a given message and placement type
  # returns a list with one item, or an empty list if the placement
  # type is not supported by Canvas
  def self.build_placement_for(placement_type, message)
    placement_name = canvas_placement_name(placement_type)

    # Return no placement if the placement type is not supported by Canvas
    unless Lti::ResourcePlacement::PLACEMENTS.include?(placement_name.to_sym)
      return []
    end

    [
      {
        placement: placement_name,
        enabled: true,
        message_type: message["type"],
        text: message["label"],
        # TODO: add support for i18n titles
        # labels: ,
        custom_fields: message["custom_parameters"],
        icon_url: message["icon_uri"],
        target_link_uri: message["target_link_uri"],
        visibility: placement_visibility(message),
        default: fetch_default_enabled_setting(message, placement_name),
        **placement_display_settings(message),
        **placement_width_and_height_settings(message, placement_name)
      }.compact
    ]
  end

  def self.placement_visibility(message)
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
  def self.fetch_default_enabled_setting(message, placement_name)
    (message[COURSE_NAV_DEFAULT_ENABLED_EXTENSION] == false && placement_name == "course_navigation") ? "disabled" : nil
  end

  def lookup_placement_overlay(placement_type)
    registration_overlay["placements"]&.find { |p| p["type"] == placement_type }
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
      response_types: [REQUIRED_RESPONSE_TYPE],
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
      tool_configuration: Schemas::LtiConfiguration.from_internal_lti_configuration(
        lti_registration.internal_lti_configuration(context: options[:context])
      ),
      default_configuration: canvas_configuration,
      registration_url:
    }.as_json(options)
  end

  def tool_id
    lti_tool_configuration[TOOL_ID_EXTENSION]
  end

  def reinstall_disabled?
    lti_tool_configuration[DISABLE_REINSTALL_EXTENSION] == true
  end

  def vendor
    lti_tool_configuration[VENDOR_EXTENSION]
  end

  def self.canvas_placement_name(placement)
    # IMS placement names that have different names in Canvas
    return "link_selection" if placement == "ContentArea"
    return "editor_button" if placement == "RichTextEditor"

    # Otherwise, remove our URL prefix from the Canvas-specific placements
    canvas_extension = CANVAS_EXTENSION_PREFIX + "/"
    placement.start_with?(canvas_extension) ? placement.sub(canvas_extension, "") : placement
  end

  # placement_* Methods used to construct placement in build_placement_for:

  def self.placement_display_settings(message)
    display_type = message[DISPLAY_TYPE_EXTENSION]
    if display_type == "new_window"
      { display_type: "default", windowTarget: "_blank" }
    else
      { display_type: }
    end
  end

  def self.placement_eula(placement_name:, eula_message:)
    if eula_message && placement_name == "ActivityAssetProcessor"
      {
        enabled: true,
        target_link_uri: eula_message["target_link_uri"],
        custom_fields: eula_message["custom_parameters"]
      }.compact
    else
      nil
    end
  end

  def self.placement_width_and_height_settings(message, placement)
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

  def message_settings
    self.class.ims_lti_config_to_internal_message_settings(lti_tool_configuration)
  end

  private

  def target_link_uri_is_uri
    return if lti_tool_configuration["target_link_uri"]&.match?(URI::DEFAULT_PARSER.make_regexp(["http", "https"]))

    errors.add(:lti_tool_configuration, "target_link_uri must be a valid URI")
  end

  def redirect_uris_contains_uris
    return if redirect_uris.all? { |uri| uri.match? URI::DEFAULT_PARSER.make_regexp(["http", "https"]) }

    errors.add(:redirect_uris, "Must only contain valid URIs")
  end

  def scopes_are_valid
    invalid_scopes = scopes - (TokenScopes::LTI_SCOPES.keys + TokenScopes::LTI_HIDDEN_SCOPES.keys)
    return if invalid_scopes.empty?

    errors.add(:scopes, "Invalid scopes: #{invalid_scopes.join(", ")}")
  end

  def lti_tool_configuration_is_valid
    Schemas::Lti::IMS::LtiToolConfiguration.simple_validation_errors(
      lti_tool_configuration,
      error_format: :hash
    )&.each { |error| errors.add(:lti_tool_configuration, error.to_json) }
  end

  def validate_overlay
    return if registration_overlay.blank?

    overlay_errors = Schemas::Lti::IMS::RegistrationOverlay.simple_validation_errors(registration_overlay)
    if overlay_errors.present?
      errors.add(:registration_overlay, overlay_errors.join("; "))
    end
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

  def canvas_placement_name(placement)
    # IMS placement names that have different names in Canvas
    return "link_selection" if placement == "ContentArea"
    return "editor_button" if placement == "RichTextEditor"

    # Otherwise, remove our URL prefix from the Canvas-specific placements
    canvas_extension = CANVAS_EXTENSION_PREFIX + "/"
    placement.start_with?(canvas_extension) ? placement.sub(canvas_extension, "") : placement
  end

  # placement_* Methods used to construct placement in build_placement_for:

  def placement_display_settings(message)
    display_type = message[DISPLAY_TYPE_EXTENSION]
    if display_type == "new_window"
      { display_type: "default", windowTarget: "_blank" }
    else
      { display_type: }
    end
  end

  def placement_visibility(message)
    availability = message[PLACEMENT_VISIBILITY_EXTENSION]
    if availability
      PLACEMENT_VISIBILITY_OPTIONS.include?(availability) ? availability : nil
    else
      nil
    end
  end

  def placement_width_and_height_settings(message, placement)
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
end
