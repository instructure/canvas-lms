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
  self.table_name = "lti_ims_registrations"

  REQUIRED_GRANT_TYPES = ["client_credentials", "implicit"].freeze
  REQUIRED_RESPONSE_TYPES = ["id_token"].freeze
  REQUIRED_APPLICATION_TYPE = "web"
  REQUIRED_TOKEN_ENDPOINT_AUTH_METHOD = "private_key_jwt"

  validates :application_type,
            :grant_types,
            :response_types,
            :redirect_uris,
            :initiate_login_uri,
            :client_name,
            :jwks_uri,
            :token_endpoint_auth_method,
            :lti_tool_configuration,
            :developer_key,
            presence: true

  validate :required_values_are_present,
           :redirect_uris_contains_uris,
           :lti_tool_configuration_is_valid,
           :scopes_are_valid

  validates :initiate_login_uri,
            :jwks_uri,
            :logo_uri,
            :client_uri,
            :tos_uri,
            :policy_uri,
            format: { with: URI::DEFAULT_PARSER.make_regexp(["http", "https"]) },
            allow_blank: true

  belongs_to :developer_key, inverse_of: :lti_registration

  def new_external_tool(context, existing_tool: nil)
    tool = existing_tool || ContextExternalTool.new(context:)
    Importers::ContextExternalToolImporter.import_from_migration(
      importable_configuration,
      context,
      nil,
      tool,
      false
    )
    tool.developer_key = developer_key
    tool.workflow_state = "active"
    tool.use_1_3 = true
    tool
  end

  private

  def required_values_are_present
    if (REQUIRED_GRANT_TYPES - grant_types).present?
      errors.add(:grant_types, "Must include #{REQUIRED_GRANT_TYPES.join(", ")}")
    end
    if (REQUIRED_RESPONSE_TYPES - response_types).present?
      errors.add(:response_types, "Must include #{REQUIRED_RESPONSE_TYPES.join(", ")}")
    end

    if token_endpoint_auth_method != REQUIRED_TOKEN_ENDPOINT_AUTH_METHOD
      errors.add(:token_endpoint_auth_method, "Must be 'private_key_jwt'")
    end

    if application_type != REQUIRED_APPLICATION_TYPE
      errors.add(:application_type, "Must be 'web'")
    end
  end

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
    config_errors = Schemas::Lti::IMS::LtiToolConfiguration.simple_validation_errors(
      lti_tool_configuration,
      error_format: :hash
    )
    return if config_errors.blank?

    errors.add(
      :lti_tool_configuration,
      # Convert errors represented as a Hash to JSON
      config_errors.is_a?(Hash) ? config_errors.to_json : config_errors
    )
  end

  # TODO: this method of only supports message/placement properties defined in
  # the Dynamic Registration specification. In the future we will need to add
  # support for all our custom top-level and placement-level properties
  # ("icon_url", "selection_height", etc.)
  def importable_configuration
    {
      "title" => client_name,
      "scopes" => scopes,
      "settings" => {
        "client_id" => global_developer_key_id
      }.merge(importable_placements),
      "public_jwk_url" => jwks_uri,
      "description" => lti_tool_configuration["description"],
      "custom_fields" => lti_tool_configuration["custom_parameters"],
      "target_link_uri" => lti_tool_configuration["target_link_uri"],
      "oidc_initiation_url" => initiate_login_uri,
      # TODO: How do we want to handle privacy level?
      "privacy_level" => "public",
      "url" => lti_tool_configuration["target_link_uri"],
      "domain" => lti_tool_configuration["domain"]
    }
  end

  def importable_placements
    lti_tool_configuration["messages"].each_with_object({}) do |message, hash|
      # In an IMS Tool Registration, a single message can have multiple placements.
      # To correctly import this, we need to duplicate the message for each desired
      # placement.
      message["placements"].each do |placement|
        hash[placement] = {
          "custom_fields" => message["custom_parameters"],
          "message_type" => message["type"],
          "placement" => placement,
          "target_link_uri" => message["target_link_uri"],
          "text" => message["label"]
        }
      end
    end
  end
end
