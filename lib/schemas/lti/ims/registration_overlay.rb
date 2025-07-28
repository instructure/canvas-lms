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

module Schemas::Lti::IMS
  # Dynamic Registration Overlay, see models/lti/ims/registration.rb
  # Based on ui/features/lti_registrations/manage/model/RegistrationOverlay.ts
  class RegistrationOverlay < ::Schemas::Base
    SCHEMA = {
      type: "object",
      additionalProperties: false,
      properties: {
        title: { type: ["string", "null"] },
        disabledScopes: {
          type: ["array", "null"],
          items: { type: "String", enum: [nil, *TokenScopes::ALL_LTI_SCOPES] },
        },
        disabledSubs: {
          type: ["array", "null"],
          items: { type: "string" }
        },
        icon_url: { type: ["string", "null"] },
        launch_height: { type: %w[string number null] },
        launch_width: { type: %w[string number null] },
        disabledPlacements: {
          type: ["array", "null"],
          items: { type: "string", enum: [nil, *Lti::ResourcePlacement::PLACEMENTS.map(&:to_s)] },
        },
        placements: {
          type: ["array", "null"],
          items: {
            type: "object",
            properties: {
              type: {
                type: "string",
                enum: [nil, *Lti::ResourcePlacement::PLACEMENTS.map(&:to_s)],
              },
              icon_url: { type: ["string", "null"] },
              label: { type: ["string", "null"] },
              launch_height: { type: %w[string number null] },
              launch_width: { type: %w[string number null] },
              default: {
                type: ["string", "null"],
                enum: [
                  nil,
                  "enabled",
                  "disabled"
                ]
              },
              required: ["type"],
              additionalProperties: false
            }
          }
        },
        description: { type: ["string", "null"] },
        privacy_level: {
          type: ["string", "null"],
          enum: [nil, *Lti::PrivacyLevelExpander::SUPPORTED_LEVELS]
        }
      }
    }.freeze

    def self.to_lti_overlay(reg_overlay)
      return {} unless reg_overlay

      reg_overlay = reg_overlay.with_indifferent_access

      {
        title: reg_overlay[:title],
        description: reg_overlay[:description],
        disabled_scopes: reg_overlay[:disabledScopes],
        disabled_placements: reg_overlay[:disabledPlacements],
        privacy_level: reg_overlay[:privacy_level],
        placements: reg_overlay[:placements].to_h do |placement|
          launch_height = placement[:launch_height] || reg_overlay[:launch_height]
          launch_width = placement[:launch_width] || reg_overlay[:launch_width]

          # There's technically the possibility for loss of info here, as the
          # overlay could have a string value for launch_height/launch_width, but
          # the Lti::Overlay only supports numbers. However, all strings should
          # just be stringified numbers, as we don't support % or other units.
          launch_height = launch_height.to_i unless launch_height.nil?
          launch_width = launch_width.to_i unless launch_width.nil?

          [
            placement[:type].to_sym,
            {
              text: placement[:label],
              icon_url: placement[:icon_url] || reg_overlay[:icon_url],
              launch_height:,
              launch_width:,
              default: placement[:default],
            }.compact
          ]
        end
      }.compact.with_indifferent_access
    end

    def self.schema
      SCHEMA
    end
  end
end
