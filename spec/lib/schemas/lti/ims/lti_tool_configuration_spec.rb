# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

describe Schemas::Lti::IMS::LtiToolConfiguration do
  describe "validation" do
    let(:valid_configuration) do
      {
        claims: [
          "sub",
          "iss",
          "name",
          "given_name",
          "family_name",
          "nickname",
          "picture",
          "email",
          "https://purl.imsglobal.org/spec/lti/claim/lis",
          "locale"
        ],
        custom_parameters: {},
        domain: "yaltt.inseng.test",
        messages: [
          {
            type: "LtiResourceLinkRequest",
            label: "testdr (https://canvas.instructure.com/lti/account_navigation)",
            custom_parameters: {
              foo: "bar",
              context_id: "$Context.id"
            },
            icon_uri: "http://yaltt.inseng.test/api/apps/2/icon.svg",
            placements: [
              "https://canvas.instructure.com/lti/account_navigation"
            ],
            roles: [],
            target_link_uri: "http://yaltt.inseng.test/api/registrations/14/launch?placement=https://canvas.instructure.com/lti/account_navigation"
          }
        ],
        target_link_uri: "http://yaltt.inseng.test/api/registrations/14/launch",
        "https://canvas.instructure.com/lti/privacy_level": "public",
        "https://canvas.instructure.com/lti/tool_id": "toolid-385"
      }
    end

    it "succeeds if configuration is valid" do
      config_errors = Schemas::Lti::IMS::LtiToolConfiguration.simple_validation_errors(
        valid_configuration,
        error_format: :hash
      )

      expect(config_errors).to be_blank
    end

    it "fails if placement is invalid" do
      invalid_placement = {
        messages: [
          {
            placements: [
              "invalid_placement"
            ]
          }
        ]
      }
      invalid_configuration = valid_configuration.deep_merge(invalid_placement)
      config_errors = Schemas::Lti::IMS::LtiToolConfiguration.simple_validation_errors(
        invalid_configuration,
        error_format: :hash
      )

      expect(config_errors).not_to be_blank
    end
  end
end
