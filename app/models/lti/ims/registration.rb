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

  validates :redirect_uris,
            :initiate_login_uri,
            :client_name,
            :jwks_uri,
            :lti_tool_configuration,
            presence: true

  validate :redirect_uris_contains_uris,
           :lti_tool_configuration_is_valid,
           :scopes_are_valid,
           :validate_overlay

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
          placements:
        }
      }]
    }.with_indifferent_access
  end

  def self.to_internal_lti_configuration(registration)
    config = registration.lti_tool_configuration

    {
      title: registration.client_name,
      description: config["description"],
      custom_fields: config["custom_parameters"],
      target_link_uri: config["target_link_uri"],
      oidc_initiation_url: registration.initiate_login_uri,
      public_jwk_url: registration.jwks_uri,
      scopes: registration.scopes,
      redirect_uris: registration.redirect_uris,
      domain: config["domain"],
      tool_id: registration.tool_id,
      privacy_level: registration.privacy_level,
      placements: registration.placements,
      launch_settings: {
        icon_url: registration.logo_uri,
        text: registration.client_name,
      }.compact
    }.compact.with_indifferent_access
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
    lti_tool_configuration["messages"].map do |message|
      if message["placements"].blank?
        # default to link_selection if no placements are specified
        [build_placement_for("link_selection", message)]
      else
        message["placements"].flat_map do |placement|
          build_placement_for(placement, message)
        end
      end
    end.flatten.uniq { |p| p[:placement] }
  end

  # Builds a placement object for a given message and placement type
  # returns a list with one item, or an empty list if the placement
  # type is not supported by Canvas
  def build_placement_for(placement_type, message)
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

    [
      {
        placement: placement_name,
        enabled: true,
        message_type: message["type"],
        text: message["label"],
        # TODO: add support for i18n titles
        # labels: ,
        custom_fields: message["custom_parameters"],
        # TODO: add support for height/width in dyn reg
        # selection_height:,
        # selection_width:,
        # launch_height:,
        # launch_width:,
        icon_url: message["icon_uri"],
        target_link_uri: message["target_link_uri"],
        display_type:,
        windowTarget: window_target,
        visibility: placement_visibility(message),
        default: fetch_default_enabled_setting(message, placement_name),
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
      default_configuration: canvas_configuration
    }.as_json(options)
  end

  def tool_id
    lti_tool_configuration[TOOL_ID_EXTENSION]
  end

  def vendor
    lti_tool_configuration[VENDOR_EXTENSION]
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
end
