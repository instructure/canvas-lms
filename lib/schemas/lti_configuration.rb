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
  # Represents the "external" JSON schema used to configure an LTI 1.3 tool,
  # as described in doc/api/lti_dev_key_config.md
  class LtiConfiguration < Base
    @schema = {
      type: "object",
      required: %w[
        title
        description
        target_link_uri
        oidc_initiation_url
      ],
      properties: {
        **InternalLtiConfiguration.base_properties,
        extensions: {
          type: :array,
          items: {
            type: "object",
            required: %w[platform settings],
            properties: {
              platform: { type: "string", description: "Must be canvas.instructure.com" },
              domain: { type: "string" },
              tool_id: { type: "string" },
              privacy_level: { type: "string", enum: ::Lti::PrivacyLevelExpander::SUPPORTED_LEVELS },
              settings: {
                type: "object",
                required: %w[placements],
                properties: {
                  **InternalLtiConfiguration.base_settings_properties,
                  placements: InternalLtiConfiguration.placements_schema,
                }
              },
            }
          }
        }
      }
    }

    # Transforms a hash conforming to the InternalLtiConfiguration schema into
    # a hash conforming to the LtiConfiguration schema.
    def self.from_internal_lti_configuration(internal_lti_config)
      config = internal_lti_config.deep_dup.deep_symbolize_keys

      settings = config.delete(:launch_settings).deep_symbolize_keys
      settings[:placements] = config.delete(:placements)
      vendor_extensions = config.delete(:vendor_extensions)

      extension_keys = %i[domain tool_id privacy_level]
      canvas_ext = config.slice(*extension_keys).merge({
        platform: "canvas.instructure.com",
        settings:
      }.deep_symbolize_keys)
      extension_keys.each { |key| config.delete(key) }

      config[:extensions] = [canvas_ext, *vendor_extensions].map(&:deep_symbolize_keys)
      config.delete(:redirect_uris)

      config
    end
  end
end
