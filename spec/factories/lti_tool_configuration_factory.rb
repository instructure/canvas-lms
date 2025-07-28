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
  LTI_TOOL_CONFIGURATION_BASE_ATTRS =
    {
      title: "LTI 1.3 Tool",
      description: "1.3 Tool",
      target_link_uri: "http://lti13testtool.docker/blti_launch",
      custom_fields: { has_expansion: "$Canvas.user.id", no_expansion: "foo" },
      public_jwk: {
        kty: "RSA",
        e: "AQAB",
        n: "2YGluTenFrEew_TWB38OE6wTaN...",
        kid: "2025-01-18T21:55:18Z",
        alg: "RS256",
        use: "sig"
      },
      public_jwk_url: "http://example.com/jwks",
      oidc_initiation_url: "http://lti13testtool.docker/login",
      oidc_initiation_urls: { "us-east-1": "http://example.com" },
      redirect_uris: ["http://lti13testtool.docker/launch"],
      scopes: [],
      domain: "lti13testtool.docker",
      tool_id: "LTI 1.3 Test Tool",
      privacy_level: "public",
      launch_settings: {
        icon_url: "https://static.thenounproject.com/png/131630-200.png",
        selection_height: 500,
        selection_width: 500,
        text: "LTI 1.3 Test Tool Extension text",
      },
      placements: [
        {
          placement: "course_navigation",
          enabled: true,
          message_type: "LtiResourceLinkRequest",
          canvas_icon_class: "icon-pdf",
          icon_url: "https://static.thenounproject.com/png/131630-211.png",
          text: "LTI 1.3 Test Tool Course Navigation",
          target_link_uri: "http://lti13testtool.docker/launch?placement=course_navigation",
        },
        {
          placement: "account_navigation",
          enabled: true,
          message_type: "LtiResourceLinkRequest",
          canvas_icon_class: "icon-lti",
          icon_url: "https://static.thenounproject.com/png/131630-211.png",
          text: "LTI 1.3 Test Tool Course Navigation",
          target_link_uri: "http://lti13testtool.docker/launch?placement=account_navigation",
        }
      ]
    }.freeze

  def lti_tool_configuration_model(**params)
    params = LTI_TOOL_CONFIGURATION_BASE_ATTRS.merge(params)
    account = params.delete(:account) || Account.default
    params[:developer_key] ||= lti_developer_key_model(account:)
    params[:lti_registration] ||= params[:developer_key].lti_registration

    @tool_configuration = Lti::ToolConfiguration.create!(params)
  end
end
