# frozen_string_literal: true

# Copyright (C) 2011 - present Instructure, Inc.
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
  LTI_IMS_REGISTRATION_BASE_ATTRS =
    {
      guid: "6378c81b-5996-4754-b850-5de78e6d22f4",
      client_name: "Test Dynamic Registration",
      client_uri: "https://example.com",
      jwks_uri: "https://example.com/api/registrations/3/jwks",
      initiate_login_uri: "https://example.com/api/registrations/3/login",
      redirect_uris: [
        "https://example.com/api/registrations/3/launch"
      ],
      scopes: %w[
        https://purl.imsglobal.org/spec/lti-ags/scope/lineitem
        https://purl.imsglobal.org/spec/lti-ags/scope/lineitem.readonly
        https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly
        https://purl.imsglobal.org/spec/lti-ags/scope/score
        https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly
        https://canvas.instructure.com/lti/public_jwk/scope/update
        https://canvas.instructure.com/lti/account_lookup/scope/show
        https://canvas.instructure.com/lti-ags/progress/scope/show
      ],
      logo_uri: "https://example.com/api/apps/1/icon.svg",
      lti_tool_configuration: {
        claims: %w[
          sub
          iss
          name
          given_name
          family_name
          nickname
          picture
          email
          locale
        ],
        custom_parameters: {},
        domain: "example.com",
        messages: [
          {
            "https://canvas.instructure.com/lti/course_navigation/default_enabled": true,
            type: "LtiResourceLinkRequest",
            icon_uri: "https://example.com/api/apps/1/icon.svg",
            label: "Test Dynamic Registration (Global Navigation)",
            custom_parameters: {
              foo: "bar",
              context_id: "$Context.id"
            },
            placements: [
              "global_navigation"
            ],
            roles: [],
            target_link_uri: "https://example.com/api/registrations/3/launch?placement=global_navigation"
          }
        ],
        target_link_uri: "https://example.com/api/registrations/3/launch",
        "https://canvas.instructure.com/lti/privacy_level": "public"
      }
    }.with_indifferent_access.freeze

  def lti_ims_registration_model(**params)
    params = LTI_IMS_REGISTRATION_BASE_ATTRS.merge(params)
    params[:developer_key] ||= developer_key_model(public_jwk_url: LTI_IMS_REGISTRATION_BASE_ATTRS[:jwks_uri], account: params.delete(:account) || account_model)
    @ims_registration = Lti::IMS::Registration.create!(params)
  end
end
