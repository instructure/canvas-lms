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

module Schemas::Lti
  class Overlay < Schemas::Base
    def schema
      {
        type: "object",
        properties: {
          title: { type: "string" },
          description: { type: "string" },
          custom_fields: { type: "object" },
          target_link_uri: { type: "string" },
          oidc_initiation_url: { type: "string" },
          domain: { type: "string" },
          privacy_level: { type: "string", enum: ::Lti::PrivacyLevelExpander::SUPPORTED_LEVELS },
          redirect_uris: { type: "array", items: { type: "string" } },
          public_jwk: { type: "object" },
          public_jwk_url: { type: "string" },
          disabled_scopes: { type: "array", items: { type: "string", enum: [*TokenScopes::LTI_SCOPES.keys, *TokenScopes::LTI_HIDDEN_SCOPES.keys] } },
          scopes: { type: "array", items: { type: "string", enum: [*TokenScopes::LTI_SCOPES.keys, *TokenScopes::LTI_HIDDEN_SCOPES.keys] } },
          disabled_placements: { type: "array", items: { type: "string", enum: ::Lti::ResourcePlacement::PLACEMENTS.map(&:to_s) } },
          placements: self.class.placements_schema,
        }
      }.freeze
    end

    def self.placements_schema
      {
        type: "object",
        additionalProperties: false,
        properties: Lti::ResourcePlacement::PLACEMENTS.index_with { placement_schema }
      }
    end

    def self.placement_schema
      {
        type: "object",
        properties: {
          text: { type: "string" },
          target_link_uri: { type: "string" },
          message_type: { type: "string", enum: ::Lti::ResourcePlacement::LTI_ADVANTAGE_MESSAGE_TYPES },
          launch_height: { type: "number" },
          launch_width: { type: "number" },
          icon_url: { type: "string" },
          default: { type: "string", enum: %w[enabled disabled] },
        }
      }.freeze
    end
  end
end
