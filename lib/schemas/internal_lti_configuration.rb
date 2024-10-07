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
    VALID_DISPLAY_TYPES = %w[default full_width full_width_in_context in_nav_context borderless].freeze

    # Transforms a hash conforming to the LtiConfiguration schema into
    # a hash conforming to the InternalLtiConfiguration schema.
    def self.from_lti_configuration(lti_config)
      config = lti_config.deep_dup.deep_symbolize_keys

      extensions = config.delete(:extensions)&.map(&:deep_symbolize_keys) || []
      canvas_ext, vendor_extensions = extensions.partition { |ext| ext[:platform] == "canvas.instructure.com" }
      canvas_ext = canvas_ext&.first || {}
      config[:vendor_extensions] = vendor_extensions if vendor_extensions.present?

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

    def schema
      {
        type: "object",
        required: %w[
          title
          description
          target_link_uri
          oidc_initiation_url
          redirect_uris
          scopes
          placements
          launch_settings
        ],
        properties: {
          **self.class.base_properties,
          redirect_uris: { type: "array", items: { type: "string" }, minItems: 1 },
          domain: { type: "string" },
          tool_id: { type: "string" },
          privacy_level: { type: "string", enum: ::Lti::PrivacyLevelExpander::SUPPORTED_LEVELS },
          launch_settings: {
            type: "object",
            properties: self.class.base_settings_properties
          },
          placements: self.class.placements_schema,
          # vendor_extensions: extensions with platform != "canvas.instructure.com", only currently copied during content migration. not present on 1.3 tools.
        }
      }.freeze
    end

    def self.base_properties
      {
        title: { type: "string", description: "Overridable by 'text' in settings and placements" },
        description: { type: "string", description: "Displayed only in assignment_selection and link_selection" },
        custom_fields: { oneOf: [{ type: "object" }, { type: "string" }], description: "Overridable in settings and placements. String for legacy purposes." },
        target_link_uri: { type: "string", description: "Overridable in settings and placements" },
        oidc_initiation_url: { type: "string" },
        oidc_initiation_urls: { type: "object" },
        public_jwk_url: { type: "string" },
        public_jwk: { type: "object" },
        scopes: { type: "array", items: { type: "string", enum: [*TokenScopes::LTI_SCOPES.keys, *TokenScopes::LTI_HIDDEN_SCOPES.keys] } },
      }.freeze
    end

    def self.base_settings_properties
      {
        message_type: { type: "string", enum: ::Lti::ResourcePlacement::LTI_ADVANTAGE_MESSAGE_TYPES },
        text: { type: "string" },
        labels: { type: "object" },
        custom_fields: { type: "object" },
        selection_height: { type: "number" },
        selection_width: { type: "number" },
        launch_height: { type: "number", description: "Not standard everywhere yet" },
        launch_width: { type: "number", description: "Not standard everywhere yet" },
        icon_url: { type: "string" },
        canvas_icon_class: { type: "string" },
        required_permissions: { type: "string" },
        windowTarget: { type: "string", enum: %w[_blank] },
        display_type: { type: "string", enum: VALID_DISPLAY_TYPES },
        url: { type: "string", description: "Defers to target_link_uri for 1.3 tools" },
        target_link_uri: { type: "string" },
        visibility: { type: "string", enum: %w[admins members public] },
        prefer_sis_email: { type: "boolean", description: "1.1 only" },
        oauth_compliant: { type: "boolean", description: "1.1 only" },
        **placement_specific_settings_properties,
      }.freeze
    end

    def self.placements_schema
      {
        type: "array",
        items: {
          type: "object",
          required: %w[placement],
          properties: {
            placement: { type: "string", enum: ::Lti::ResourcePlacement::PLACEMENTS.map(&:to_s) },
            enabled: { type: "boolean" },
            **base_settings_properties
          },
          allOf: [
            {
              if: {
                properties: { placement: { const: "submission_type_selection" } }
              },
              then: {
                properties: {
                  description: { type: "string", maxLength: 255, errorMessage: "description must be a string with a maximum length of 255" },
                  require_resource_selection: { type: "boolean" },
                }
              }
            },
            {
              if: {
                properties: { placement: { const: "account_navigation" } }
              },
              then: {
                properties: {
                  root_account_only: { type: "boolean" },
                  default: { type: "string", enum: %w[disabled enabled] },
                }
              }
            },
            {
              if: {
                properties: { placement: { const: "global_navigation" } }
              },
              then: {
                properties: { icon_svg_path_64: { type: "string" } }
              }
            },
            {
              if: {
                properties: { placement: { const: "file_menu" } }
              },
              then: {
                properties: { accept_media_types: { type: "string" } }
              }
            },
            {
              if: {
                properties: { placement: { const: "editor_button" } }
              },
              then: {
                properties: { use_tray: { type: "boolean" } }
              }
            }
          ]

        }
      }.freeze
    end

    # These can be set in the base-level settings, but only apply to specific placements
    def self.placement_specific_settings_properties
      {
        icon_svg_path_64: { type: "string", description: "Used only by global_navigation" },
        default: { type: "string", enum: %w[disabled enabled], description: "Used only by account_navigation and course_navigation" },
        accept_media_types: { type: "string", description: "Used only by file_menu" },
        use_tray: { type: "boolean", description: "Used only by editor_button" },
      }.freeze
    end
  end
end
