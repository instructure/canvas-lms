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
module Schemas::Lti::IMS
  class LtiToolConfiguration < Schemas::Base
    SCHEMA = {
      "type" => "object",
      "required" => %w[
        domain
        messages
        claims
      ].freeze,
      "properties" => {
        "domain" => { "type" => "string" }.freeze,
        "secondary_domains" => {
          "type" => "array",
          "items" => {
            "type" => "string"
          }.freeze
        }.freeze,
        "target_link_uri" => { "type" => "string" }.freeze,
        "custom_parameters" => {
          "type" => "object",
          "additionalProperties" => {
            "type" => "string"
          }.freeze
        }.freeze,
        "description" => { "type" => "string" }.freeze,
        "messages" => {
          "type" => "array",
          "items" => {
            "type" => "object",
            "required" => [
              "type"
            ].freeze,
            "properties" => {
              "type" => {
                "type" => "string",
                "enum" => Lti::ResourcePlacement::PLACEMENTS_BY_MESSAGE_TYPE.keys
              }.freeze,
              "target_link_uri" => { "type" => "string" }.freeze,
              "label" => { "type" => "string" }.freeze,
              "icon_uri" => { "type" => "string" }.freeze,
              "custom_parameters" => {
                "type" => "object",
                "additionalProperties" => {
                  "type" => "string"
                }.freeze
              }.freeze,
              "placements" => {
                "type" => "array",
                "items" => {
                  "type" => "string",
                  "enum" => Lti::ResourcePlacement::PLACEMENTS.map(&:to_s)
                }.freeze
              }.freeze,
            }.freeze
          }
        }.freeze,
        "claims" => {
          "type" => "array",
          "items" => {
            "type" => "string"
          }.freeze
        }.freeze,
      }.freeze
    }.freeze

    TYPE = "https://purl.imsglobal.org/spec/lti-tool-configuration"

    def schema
      SCHEMA
    end
  end
end
