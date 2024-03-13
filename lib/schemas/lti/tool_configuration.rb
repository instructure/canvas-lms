# frozen_string_literal: true

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

module Schemas::Lti
  class ToolConfiguration < Schemas::Base
    LAUNCH_INFO_SCHEMA =
      {
        "target_link_uri" => {
          "type" => "string"
        }.freeze,
        "text" => {
          "type" => "string"
        }.freeze,
        "icon_url" => {
          "type" => "string"
        }.freeze,
        "message_type" => {
          "type" => "string",
          "enum" => %w[LtiDeepLinkingRequest LtiResourceLinkRequest].freeze
        }.freeze,
        "canvas_icon_class" => {
          "type" => "string"
        }.freeze,
        "selection_width" => {
          "type" => "number"
        }.freeze,
        "selection_height" => {
          "type" => "number"
        }.freeze,
      }.freeze

    SCHEMA = {
      "type" => "object",
      "required" => [
        "title",
        "description",
        # to be reenabled after scopes bug fix
        # "scopes",
        "target_link_uri",
        "oidc_initiation_url"
      ].freeze,
      "properties" => {
        "title" => {
          "type" => "string"
        }.freeze,
        # "public_jwk" => verified in ToolConfiguration model
        "public_jwk_url" => {
          "type" => "string"
        }.freeze,
        "is_lti_key" => {
          "type" => "boolean"
        }.freeze,
        "description" => {
          "type" => "string"
        }.freeze,
        "icon_url" => {
          "type" => "string"
        }.freeze,
        "scopes" => {
          "type" => "array",
          "items" => {
            "type" => "string",
            "enum" => [*TokenScopes::LTI_SCOPES.keys, *TokenScopes::LTI_HIDDEN_SCOPES.keys].freeze
          }
        }.freeze,
        "extensions" => {
          "type" => "array",
          "items" => {
            "type" => "object",
            "required" => %w[platform settings].freeze,
            "properties" => {
              "domain" => {
                "type" => "string"
              }.freeze,
              "tool_id" => {
                "type" => "string"
              }.freeze,
              "platform" => {
                "type" => "string"
              }.freeze,
              "settings" => {
                "type" => "object",
                "required" => [
                  "placements"
                ].freeze,
                "properties" => {
                  "text" => {
                    "type" => "string"
                  }.freeze,
                  "icon_url" => {
                    "type" => "string"
                  }.freeze,
                  "placements" => {
                    "type" => "array",
                    "items" =>
                      { "oneOf" => [
                        {
                          "type" => "object",
                          "required" => [
                            "placement"
                          ].freeze,
                          "properties" => {
                            "placement" => {
                              "type" => "string",
                              "enum" => (Lti::ResourcePlacement::PLACEMENTS - [:submission_type_selection]).map(&:to_s).freeze
                            }.freeze,
                            **LAUNCH_INFO_SCHEMA,
                          }.freeze
                        }.freeze,
                        {
                          "type" => "object",
                          "required" => [
                            "placement"
                          ].freeze,
                          "properties" => {
                            "placement" => {
                              "type" => "string",
                              "pattern" => "^submission_type_selection$"
                            }.freeze,
                            "description" => {
                              "type" => "string",
                              "maxLength" => 255,
                              "errorMessage" => "description must be a string with a maximum length of 255 characters"
                            }.freeze,
                            **LAUNCH_INFO_SCHEMA,
                          }.freeze
                        }.freeze
                      ].freeze }.freeze
                  }.freeze
                }.freeze
              }.freeze,
              "privacy_level" => {
                "type" => "string",
                "enum" => %w[
                  public
                  email_only
                  name_only
                  anonymous
                ].freeze
              }.freeze
            }.freeze
          }.freeze
        }.freeze,
        "target_link_uri" => {
          "type" => "string"
        }.freeze,
        "oidc_initiation_url" => {
          "type" => "string",
        }.freeze,
        "oidc_initiation_urls" => {
          "type" => "object"
        }.freeze,
        "custom_fields" => {
          "anyOf" => [
            { "type" => "string" }.freeze,
            { "type" => "object" }.freeze
          ].freeze
        }.freeze
      }.freeze
    }.freeze

    private

    def schema
      SCHEMA
    end
  end
end
