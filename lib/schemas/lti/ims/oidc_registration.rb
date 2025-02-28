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
  # For Dynamic Registration. OIDCReg as per spec
  # https://www.imsglobal.org/spec/lti-dr/v1p0#tool-configuration and
  # https://openid.net/specs/openid-connect-registration-1_0.html
  class OidcRegistration < ::Schemas::Base
    SCHEMA =
      {
        type: "object",
        properties: {
          # Required properties:
          :application_type => {
            type: "string",
            const: Lti::IMS::Registration::REQUIRED_APPLICATION_TYPE,
          },
          :grant_types => {
            allOf: [
              {
                type: "array",
                items: { type: "string" },
                minLength: 2,
              },
              *Lti::IMS::Registration::REQUIRED_GRANT_TYPES.map do |grant_type|
                { contains: { const: grant_type } }
              end,
            ],
          },
          :response_types => {
            type: "array",
            items: {
              type: "string",
            },
            minItems: 1,
            contains: {
              const: Lti::IMS::Registration::REQUIRED_RESPONSE_TYPE
            }
          },
          :redirect_uris => {
            type: "array",
            items: {
              type: "string",
              format: "uri"
            },
            minItems: 1
          },
          :initiate_login_uri => { type: "string", format: "uri" },
          :client_name => { type: "string", minLength: 1 },
          :jwks_uri => { type: "string", format: "uri" },
          :token_endpoint_auth_method => {
            type: "string",
            const: Lti::IMS::Registration::REQUIRED_TOKEN_ENDPOINT_AUTH_METHOD,
          },
          ::Schemas::Lti::IMS::LtiToolConfiguration::TYPE =>
              ::Schemas::Lti::IMS::LtiToolConfiguration::SCHEMA,

          # Optional properties
          # this is (at least somewhat) implied as required in the spec, we
          # don't require it (default to [])
          :scope => { type: ["string", "null"] },
          :contacts => {
            type: "array",
            items: { type: "string", format: "email" },
          },
          :client_uri => { type: ["string", "null"], format: "uri" },
          :logo_uri => { type: ["string", "null"], format: "uri" },
          :tos_uri => { type: ["string", "null"], format: "uri" },
          :policy_uri => { type: ["string", "null"], format: "uri" },
        },
        required: %w[
          application_type
          grant_types
          response_types
          redirect_uris
          initiate_login_uri
          client_name
          jwks_uri
          token_endpoint_auth_method
          https://purl.imsglobal.org/spec/lti-tool-configuration
        ],
        additionalProperties: true
      }.freeze

    # Filters to permitted properties, modifies hash in place
    # Requires string keys
    def self.filter!(hash)
      filter_properties!(hash, SCHEMA)
      Schemas::Lti::IMS::LtiToolConfiguration.filter!(
        hash[Schemas::Lti::IMS::LtiToolConfiguration::TYPE]
      )
    end

    # Validates and filters to permitted properties. Returns {errors:, registration_params:}
    # (one of which will be nil)
    def self.validate_and_filter(raw_params)
      result = raw_params.deep_stringify_keys
      errors = simple_validation_errors(result)
      if errors.present?
        { errors:, registration_params: nil }
      else
        filter!(result)
        { registration_params: result, errors: nil }
      end
    end

    # Filters to permitted properties, then renames fields the way
    # the Lti::IMS::Registration model expects, so can be fed into
    # Lti::IMS::Registration.new(**registration_attrs)
    # Returns {errors:, registration_attrs:}, one of which will be nil
    def self.to_model_attrs(raw_params)
      validate_and_filter(raw_params) => { errors:, registration_params: }

      registration_attrs =
        if registration_params.present?
          reg_attrs = registration_params.except(
            *Lti::IMS::Registration::IMPLIED_SPEC_ATTRIBUTES
          )
          reg_attrs["scopes"] = reg_attrs.delete("scope")&.split || []
          reg_attrs["scopes"].delete("openid")
          reg_attrs["lti_tool_configuration"] =
            reg_attrs.delete("https://purl.imsglobal.org/spec/lti-tool-configuration")
          reg_attrs
        else
          nil
        end

      { errors:, registration_attrs: }
    end

    def self.schema
      SCHEMA
    end
  end
end
