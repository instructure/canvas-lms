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

RSpec.shared_context "lti_1_3_tool_configuration_spec_helper", shared_context: :metadata do
  let_once(:canvas_lti_configuration) do
    {
      title: "LTI 1.3 Tool",
      description: "1.3 Tool",
      target_link_uri: "http://lti13testtool.docker/blti_launch",
      custom_fields: {
        has_expansion: "$Canvas.user.id",
        no_expansion: "foo"
      }.with_indifferent_access,
      public_jwk: {
        kty: "RSA",
        e: "AQAB",
        n: "2YGluUtCi62Ww_TWB38OE6wTaN...",
        kid: "2018-09-18T21:55:18Z",
        alg: "RS256",
        use: "sig"
      }.with_indifferent_access,
      public_jwk_url: "http://example.com/jwks",
      oidc_initiation_url: "http://lti13testtool.docker/blti_launch",
      oidc_initiation_urls: {
        "us-east-1": "http://example.com"
      }.with_indifferent_access,
      scopes: [],
      extensions: [
        {
          platform: "canvas.instructure.com",
          privacy_level: "public",
          tool_id: "LTI 1.3 Test Tool",
          domain: "lti13testtool.docker",
          settings: {
            icon_url: "https://static.thenounproject.com/png/131630-200.png",
            selection_height: 500,
            selection_width: 500,
            text: "LTI 1.3 Test Tool Extension text",
            placements: [
              {
                placement: "course_navigation",
                message_type: "LtiResourceLinkRequest",
                canvas_icon_class: "icon-pdf",
                icon_url: "https://static.thenounproject.com/png/131630-211.png",
                text: "LTI 1.3 Test Tool Course Navigation",
                target_link_uri: "http://lti13testtool.docker/launch?placement=course_navigation",
                enabled: true
              }.with_indifferent_access,
              {
                placement: "account_navigation",
                message_type: "LtiResourceLinkRequest",
                canvas_icon_class: "icon-lti",
                icon_url: "https://static.thenounproject.com/png/131630-211.png",
                target_link_uri: "http://lti13testtool.docker/launch?placement=account_navigation",
                text: "LTI 1.3 Test Tool Course Navigation",
                enabled: true
              }.with_indifferent_access
            ]
          }.with_indifferent_access
        }
      ]
    }.with_indifferent_access
  end

  # functionally equivalent to `canvas_lti_configuration` above, but in the
  # InternalLtiConfiguration format
  let_once(:internal_lti_configuration) do
    Schemas::InternalLtiConfiguration.from_lti_configuration(canvas_lti_configuration).tap do |config|
      config[:redirect_uris] = [config[:target_link_uri]]
    end
  end
end
