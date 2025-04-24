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
#

# Schema for a https://purl.imsglobal.org/spec/lti-tool-configuration
# See https://www.imsglobal.org/spec/lti-dr/v1p0#tool-configuration
# See also Schemas::Lti::IMS::OidcRegistration which uses this
module Schemas::Lti::IMS
  class LtiToolConfiguration < Schemas::Base
    VALID_DISPLAY_TYPES = [*Schemas::InternalLtiConfiguration::VALID_DISPLAY_TYPES, "new_window"].freeze

    CUSTOM_PARAMS_SCHEMA = {
      "type" => "object",
      "additionalProperties" => {
        "type" => "string"
      }.freeze
    }.freeze

    LTI_MESSAGE_SCHEMA = {
      "type" => "object",
      "required" => ["type"].freeze,
      "additionalProperties" => true,
      "properties" => {
        # Required properties
        "type" => {
          "type" => "string",
          "enum" => Lti::ResourcePlacement::PLACEMENTS_BY_MESSAGE_TYPE.keys
        }.freeze,

        # Optional properties
        "target_link_uri" => { "type" => %w[string null].freeze, "format" => "uri" }.freeze,

        # TODO: support label#ja etc.
        "label" => { "type" => %w[string null].freeze }.freeze,
        "icon_uri" => { "type" => %w[string null].freeze, "format" => "uri" }.freeze,
        "custom_parameters" => CUSTOM_PARAMS_SCHEMA,
        "roles" => { type: ["array"], items: { type: "string" }.freeze }.freeze,
        "placements" => {
          "type" => "array",
          "items" => {
            "type" => "string",
            "enum" =>
              Lti::ResourcePlacement::PLACEMENTS.map(&:to_s) +
              Lti::ResourcePlacement::PLACEMENTS.map do |p|
                Lti::ResourcePlacement.add_extension_prefix_if_necessary(p)
              end + [
                Lti::ResourcePlacement::CONTENT_AREA,
                Lti::ResourcePlacement::RICH_TEXT_EDITOR
              ]
          }.freeze
        }.freeze,

        # Optional extensions
        Lti::IMS::Registration::COURSE_NAV_DEFAULT_ENABLED_EXTENSION =>
          { type: "boolean" }.freeze,
        Lti::IMS::Registration::PLACEMENT_VISIBILITY_EXTENSION =>
          { type: %w[string null].freeze, enum: [nil, *Lti::IMS::Registration::PLACEMENT_VISIBILITY_OPTIONS].freeze }.freeze,
        Lti::IMS::Registration::DISPLAY_TYPE_EXTENSION =>
          { type: %w[string null].freeze, enum: [nil, *VALID_DISPLAY_TYPES] }.freeze,
        Lti::IMS::Registration::LAUNCH_WIDTH_EXTENSION =>
          { type: %w[integer string null] }.freeze,
        Lti::IMS::Registration::LAUNCH_HEIGHT_EXTENSION =>
          { type: %w[integer string null] }.freeze,
      }.freeze
    }.freeze

    SCHEMA = {
      "type" => "object",
      "required" => %w[
        domain
        messages
        claims
      ].freeze,
      "properties" => {
        # Required properties
        "domain" => {
          "type" => "string",
          "description" => "The primary domain covered by this tool; protocol must not be included. For example mytool.example.org",
          # https://stackoverflow.com/questions/106179/regular-expression-to-match-dns-hostname-or-ip-address
          # plus port (:[0-9]{1,5})?
          "pattern" => "^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9])\\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9-]*[A-Za-z0-9])(:[0-9]{1,5})?$",
        },
        "messages" => {
          "type" => "array",
          "items" => LTI_MESSAGE_SCHEMA,
        }.freeze,
        "claims" => {
          "type" => "array",
          "items" => {
            "type" => "string"
          }.freeze
        }.freeze,

        # Optional properties
        "secondary_domains" => {
          "type" => "array",
          "items" => {
            "type" => "string",
            "format" => "hostname"
          }.freeze
        }.freeze,
        "deployment_id" => { "type" => %w[string null] }.freeze,
        "target_link_uri" => { "type" => %w[string null] }.freeze,
        "custom_parameters" => CUSTOM_PARAMS_SCHEMA,
        "description" => { "type" => %w[string null] }.freeze,

        # Optional extensions
        ::Lti::IMS::Registration::PRIVACY_LEVEL_EXTENSION =>
          { type: %w[string null], enum: [nil, *Lti::PrivacyLevelExpander::SUPPORTED_LEVELS] },
        ::Lti::IMS::Registration::TOOL_ID_EXTENSION => { type: %w[string null] },
        ::Lti::IMS::Registration::VENDOR_EXTENSION => { type: %w[string null] },
      }.freeze
    }.freeze

    TYPE = "https://purl.imsglobal.org/spec/lti-tool-configuration"

    def self.schema
      SCHEMA
    end

    def self.filter!(json_hash)
      filter_properties!(json_hash, SCHEMA)
      filter_properties!(json_hash["messages"], LTI_MESSAGE_SCHEMA)
    end
  end
end
