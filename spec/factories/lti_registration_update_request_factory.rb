# frozen_string_literal: true

# Copyright (C) 2025 - present Instructure, Inc.
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

module Factories
  DEFAULT_LTI_IMS_REGISTRATION_UPDATE_ATTRS = {
    "application_type" => "web",
    "grant_types" => ["client_credentials", "implicit"],
    "response_types" => ["id_token"],
    "redirect_uris" => ["https://example.com/launch"],
    "initiate_login_uri" => "https://example.com/login",
    "client_name" => "Updated Test Registration",
    "jwks_uri" => "https://example.com/api/jwks",
    "token_endpoint_auth_method" => "private_key_jwt",
    "logo_uri" => "https://example.com/logo.jpg",
    "https://purl.imsglobal.org/spec/lti-tool-configuration" => {
      "domain" => "example.com",
      "messages" => [{
        "type" => "LtiResourceLinkRequest",
        "label" => "updated label",
        "placements" => ["course_navigation"],
        "target_link_uri" => "https://example.com/launch",
        "custom_parameters" => {
          "updated_foo" => "updated_bar"
        },
        "roles" => [
          "http://purl.imsglobal.org/vocab/lis/v2/membership#ContentDeveloper",
          "http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor"
        ],
        "icon_uri" => "https://example.com/icon.jpg"
      }],
      "custom_parameters" => {
        "global_updated_foo" => "global_updated_bar"
      },
      "claims" => ["iss", "sub"],
      "target_link_uri" => "https://example.com/launch",
      "https://canvas.instructure.com/lti/privacy_level" => "email_only",
      "https://canvas.instructure.com/lti/vendor" => "Updated Vendor"
    },
    "scope" => "https://purl.imsglobal.org/spec/lti-ags/scope/score https://canvas.instructure.com/lti/data_services/scope/create"
  }.with_indifferent_access.freeze

  def lti_ims_registration_update_request_model(**params)
    Schemas::Lti::IMS::OidcRegistration.to_model_attrs(DEFAULT_LTI_IMS_REGISTRATION_UPDATE_ATTRS) => { errors:, registration_attrs: }
    params[:lti_registration] ||= lti_registration_model(account: params[:root_account] || account_model)
    params[:root_account] ||= params[:lti_registration].account
    params[:created_by] ||= user_model
    params[:uuid] ||= SecureRandom.uuid
    params[:lti_ims_registration] ||= registration_attrs
    params[:created_at] ||= 1.hour.ago

    @lti_registration_update_request = Lti::RegistrationUpdateRequest.create!(params)
  end
end
