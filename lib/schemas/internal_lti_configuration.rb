# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

module Schemas
  # Represents the "internal" JSON schema used to configure an LTI 1.3 tool,
  # as stored in Lti::ToolConfiguration and used in Lti::Registration.
  class InternalLtiConfiguration < Base
    VALID_DISPLAY_TYPES = %w[default full_width full_width_in_context full_width_with_nav in_nav_context borderless].freeze

    # Transforms a hash conforming to the LtiConfiguration schema into
    # a hash conforming to the InternalLtiConfiguration schema.
    def self.from_lti_configuration(lti_config)
      config = lti_config.deep_dup.deep_symbolize_keys

      extensions = config.delete(:extensions)&.map(&:deep_symbolize_keys) || []
      canvas_ext, vendor_extensions = extensions.partition { |ext| ext[:platform] == "canvas.instructure.com" }
      canvas_ext = canvas_ext&.first || {}
      config[:vendor_extensions] = vendor_extensions if vendor_extensions.present?
      config[:scopes] ||= []

      canvas_ext.delete(:platform)
      launch_settings = canvas_ext.delete(:settings)&.deep_symbolize_keys || {}
      placements = launch_settings&.delete(:placements) || []
      launch_settings&.reject! { |k, _| ::Lti::ResourcePlacement::PLACEMENTS.include?(k.to_sym) }

      config.merge({
        **canvas_ext,
        launch_settings:,
        placements:,
      }.deep_symbolize_keys)
    end

    # Transforms a hash conforming to the InternalLtiConfiguration schema into
    # a hash that's suitable for importing using the ContextExternalToolImporter.
    # @param [Hash] internal_config The internal configuration hash.
    # @return [Hash] The importable configuration hash.
    def self.to_deployment_configuration(internal_config, unified_tool_id: nil)
      config = internal_config.deep_dup.with_indifferent_access
      placements = config&.dig(:placements)

      settings = {
        **(config&.dig(:launch_settings) || {}),
        placements:,
      }

      # legacy: add placements in both array and hash form
      placements&.each do |p|
        settings[p["placement"]] = p
      end

      config
        .except(:redirect_uris, :launch_settings, :placements)
        .merge({ settings:, unified_tool_id:, lti_version: "1.3", url: config[:target_link_uri] })
        .with_indifferent_access.compact
    end

    def self.schema
      {
        type: "object",
        required: %w[
          title
          target_link_uri
          oidc_initiation_url
          redirect_uris
          scopes
          placements
          launch_settings
        ],
        properties: {
          **base_properties,
          redirect_uris: { type: "array", items: { type: "string" }, minItems: 1 },
          domain: { type: "string" },
          tool_id: { type: "string" },
          privacy_level: { type: "string", enum: ::Lti::PrivacyLevelExpander::SUPPORTED_LEVELS },
          launch_settings: {
            type: "object",
            properties: base_settings_properties
          },
          placements: placements_schema,
          # vendor_extensions: extensions with platform != "canvas.instructure.com", only currently copied during content migration. not present on 1.3 tools.
        }
      }
    end

    def self.allowed_base_properties
      schema[:properties].keys
    end

    def self.base_properties
      {
        title: { type: "string", description: "Overridable by 'text' in settings and placements" },
        description: { type: "string", description: "Displayed only in assignment_selection, link_selection, and ActivityAssetProcessor" },
        custom_fields: { oneOf: [{ type: "object" }, { type: "string" }], description: "Overridable in settings and placements. String for legacy purposes." },
        target_link_uri: { type: "string", description: "Overridable in settings and placements" },
        oidc_initiation_url: { type: "string" },
        oidc_initiation_urls: { type: "object" },
        public_jwk_url: { type: "string" },
        public_jwk: { type: ["object", "array"] }, # account for legacy invalid data
        scopes: { type: "array", items: { type: "string", enum: [*TokenScopes::LTI_SCOPES.keys, *TokenScopes::LTI_HIDDEN_SCOPES.keys] } },
      }.freeze
    end

    def self.base_settings_properties
      {
        message_type: { type: "string", enum: ::Lti::ResourcePlacement::LTI_ADVANTAGE_MESSAGE_TYPES },
        text: { type: "string" },
        labels: { type: "object" },
        custom_fields: { type: "object" },
        selection_height: { type: ["number", "string"] },
        selection_width: { type: ["number", "string"] },
        launch_height: { type: ["number", "string"], description: "Not standard everywhere yet" },
        launch_width: { type: ["number", "string"], description: "Not standard everywhere yet" },
        icon_url: { type: "string" },
        canvas_icon_class: { type: "string" },
        required_permissions: { type: "string" },
        windowTarget: { type: ["string", "null"], description: "only '_blank' supported" }, # , enum: %w[_blank] },
        display_type: { type: "string", enum: VALID_DISPLAY_TYPES },
        url: { type: "string", description: "Defers to target_link_uri for 1.3 tools" },
        target_link_uri: { type: "string" },
        visibility: { type: "string", enum: %w[admins members public] },
        prefer_sis_email: { type: "boolean", description: "1.1 only" },
        oauth_compliant: { type: "boolean", description: "1.1 only" },
        **placement_specific_settings_properties,
      }.freeze
    end

    def self.make_placement_specific_properties(**placement_properties_hash)
      placement_properties_hash.map do |placement, properties|
        {
          if: { properties: { placement: { const: placement.to_s } } },
          then: { properties: }
        }
      end
    end

    def self.placements_schema
      {
        type: "array",
        items: {
          type: "object",
          required: %w[placement],
          properties: {
            placement: { type: "string", enum: ::Lti::ResourcePlacement::PLACEMENTS.map(&:to_s) },
            enabled: { type: ["boolean", "string"] },
            **base_settings_properties
          },
          allOf: make_placement_specific_properties(
            account_navigation: {
              root_account_only: { type: "boolean" },
              default: { type: "string" }, # , enum: %w[disabled enabled] },
            },
            editor_button: { use_tray: { type: ["boolean", "string"] } },
            file_menu: { accept_media_types: { type: "string" } },
            global_navigation: { icon_svg_path_64: { type: "string" } },
            submission_type_selection: {
              description: { type: "string", maxLength: 255, errorMessage: "description must be a string with a maximum length of 255" },
              require_resource_selection: { type: "boolean" },
            },
            ActivityAssetProcessor: {
              eula: { type: "object", properties: asset_processor_eula_properties },
            }
          )
        }
      }.freeze
    end

    def self.asset_processor_eula_properties
      {
        target_link_uri: { type: "string" },
        custom_fields: { type: "object", additionalProperties: { type: "string" } },
      }
    end

    # These can be set in the base-level settings, but only apply to specific placements
    def self.placement_specific_settings_properties
      {
        icon_svg_path_64: { type: "string", description: "Used only by global_navigation" },
        default: { type: "string", description: "Used only by account_navigation and course_navigation" }, # enum: %w[disabled enabled],
        accept_media_types: { type: "string", description: "Used only by file_menu" },
        use_tray: { type: ["boolean", "string"], description: "Used only by editor_button" },
      }.freeze
    end
  end
end
