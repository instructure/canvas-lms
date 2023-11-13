# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

module Lti::IMS
  describe Registration do
    let(:application_type) { :web }
    let(:grant_types) { [:client_credentials, :implicit] }
    let(:response_types) { [:id_token] }
    let(:redirect_uris) { ["http://example.com"] }
    let(:initiate_login_uri) { "http://example.com/login" }
    let(:client_name) { "Example Tool" }
    let(:jwks_uri) { "http://example.com/jwks" }
    let(:logo_uri) { "http://example.com/logo.png" }
    let(:client_uri) { "http://example.com/" }
    let(:tos_uri) { "http://example.com/tos" }
    let(:policy_uri) { "http://example.com/policy" }
    let(:token_endpoint_auth_method) { "private_key_jwt" }
    let(:lti_tool_configuration) do
      {
        domain: "example.com",
        messages: [],
        claims: []
      }
    end
    let(:scopes) { [] }

    let(:registration) do
      r = Registration.new({
        application_type:,
        grant_types:,
        response_types:,
        redirect_uris:,
        initiate_login_uri:,
        client_name:,
        jwks_uri:,
        logo_uri:,
        client_uri:,
        tos_uri:,
        policy_uri:,
        token_endpoint_auth_method:,
        lti_tool_configuration:,
        scopes:
      }.compact)
      r.developer_key = developer_key
      r
    end
    let(:developer_key) { DeveloperKey.create }

    describe "validations" do
      subject { registration.validate }

      context "when valid" do
        it { is_expected.to be true }
      end

      context "application_type" do
        context "is \"web\"" do
          it { is_expected.to be true }
        end

        context "is not \"web\"" do
          let(:application_type) { "native" }

          it { is_expected.to be false }
        end

        context "is not included" do
          let(:application_type) { nil }

          it { is_expected.to be false }
        end
      end

      context "grant_types" do
        context "includes other types" do
          let(:grant_types) { %i[client_credentials implicit foo bar] }

          it { is_expected.to be true }
        end

        context "does not include implicit" do
          let(:grant_types) { [:client_credentials, :foo] }

          it { is_expected.to be false }
        end

        context "does not include client_credentials" do
          let(:grant_types) { [:implicit, :foo] }

          it { is_expected.to be false }
        end
      end

      context "response_types" do
        context "includes other types" do
          let(:response_types) { %i[id_token foo bar] }

          it { is_expected.to be true }
        end

        context "is not included" do
          let(:response_types) { nil }

          it { is_expected.to be false }
        end

        context "does not include id_token" do
          let(:response_types) { [:foo, :bar] }

          it { is_expected.to be false }
        end
      end

      context "redirect_uris" do
        context "includes valid uris" do
          let(:redirect_uris) { ["https://example.com", "https://example.com/foo"] }

          it { is_expected.to be true }
        end

        context "is not included" do
          let(:redirect_uris) { nil }

          it { is_expected.to be false }
        end

        context "includes a non-url" do
          let(:redirect_uris) { ["https://example.com", "asdf"] }

          it { is_expected.to be false }
        end
      end

      context "initiate_login_uri" do
        context "is not included" do
          let(:initiate_login_uri) { nil }

          it { is_expected.to be false }
        end

        context "is a valid uri" do
          let(:initiate_login_uri) { "http://example.com/login" }

          it { is_expected.to be true }
        end

        context "is not a valid uri" do
          let(:initiate_login_uri) { "asdf" }

          it { is_expected.to be false }
        end
      end

      context "client_name" do
        context "is not included" do
          let(:client_name) { nil }

          it { is_expected.to be false }
        end
      end

      context "jwks_uri" do
        context "is not included" do
          let(:jwks_uri) { nil }

          it { is_expected.to be false }
        end

        context "is not a valid uri" do
          let(:jwks_uri) { "asdf" }

          it { is_expected.to be false }
        end
      end

      context "token_endpoint_auth_method" do
        context "is not \"private_key_jwt\"" do
          let(:token_endpoint_auth_method) { "asdf" }

          it { is_expected.to be false }
        end
      end

      context "logo_uri" do
        context "is not a valid uri" do
          let(:logo_uri) { "asdf" }

          it { is_expected.to be false }
        end
      end

      context "client_uri" do
        context "is not a valid uri" do
          let(:client_uri) { "asdf" }

          it { is_expected.to be false }
        end
      end

      context "tos_uri" do
        context "is not a valid uri" do
          let(:tos_uri) { "asdf" }

          it { is_expected.to be false }
        end
      end

      context "policy_uri" do
        context "is not a valid uri" do
          let(:policy_uri) { "asdf" }

          it { is_expected.to be false }
        end
      end

      context "scopes" do
        context "contains invalid scopes" do
          let(:scopes) { ["asdf"] }

          it { is_expected.to be false }
        end
      end
    end

    describe "canvas_configuration" do
      subject { registration.canvas_configuration }

      context "should return a correct configuration" do
        it do
          expect(subject).to eq({
                                  "custom_parameters" => nil,
                                  "description" => nil,
                                  "extensions" => [{
                                    "domain" => "example.com",
                                    "platform" => "canvas.instructure.com",
                                    "privacy_level" => "public",
                                    "settings" => {
                                      "icon_url" => nil,
                                      "placements" => [],
                                      "platform" => "canvas.instructure.com",
                                      "text" => "Example Tool",
                                    },
                                    "tool_id" => "Example Tool"
                                  }],
                                  "oidc_initiation_url" => "http://example.com/login",
                                  "public_jwk_url" => "http://example.com/jwks",
                                  "scopes" => [],
                                  "target_link_uri" => nil,
                                  "title" => "Example Tool",
                                  "url" => nil,
                                })
        end
      end
    end

    describe "placements" do
      let(:lti_tool_configuration) do
        {
          domain: "example.com",
          messages: [{
            type: "LtiResourceLinkRequest",
            target_link_uri: "http://example.com/launch",
            custom_parameters: {
              "foo" => "bar"
            },
            icon_uri: "http://example.com/icon.png",
            placements: [
              "https://canvas.instructure.com/lti/assignment_edit",
              "global_navigation",
              "course_navigation",
              "ContentArea",
              "RichTextEditor",
            ],
          }],
          claims: []
        }
      end

      subject { registration.placements }

      context "convert messages to placements" do
        it "accepts valid placements" do
          canvas_placement_hash = {
            custom_fields: { "foo" => "bar" },
            enabled: true,
            icon_url: "http://example.com/icon.png",
            message_type: "LtiResourceLinkRequest",
            target_link_uri: "http://example.com/launch"
          }
          expect(subject).to eq [
            canvas_placement_hash.merge(placement: "assignment_edit"),
            canvas_placement_hash.merge(placement: "global_navigation"),
            canvas_placement_hash.merge(placement: "course_navigation"),
            canvas_placement_hash.merge(placement: "link_selection"),
            canvas_placement_hash.merge(placement: "editor_button"),
          ]
        end

        it "rejects invalid placements" do
          bad_placement_name = "course_navigationhttps://canvas.instructure.com/lti/"
          registration.lti_tool_configuration["messages"].first["placements"] << bad_placement_name
          expect { registration.save! }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end

    describe "importable_configuration" do
      subject { registration.importable_configuration }
      let(:lti_tool_configuration) do
        {
          domain: "example.com",
          messages: [{
            type: "LtiResourceLinkRequest",
            target_link_uri: "http://example.com/launch",
            custom_parameters: {
              "foo" => "bar"
            },
            icon_uri: "http://example.com/icon.png",
            placements: ["global_navigation", "course_navigation"],
          }],
          claims: []
        }
      end

      context "should return a correct configuration" do
        it do
          expect(subject).to eq(
            {
              "custom_parameters" => nil,
              "description" => nil,
              "domain" => "example.com",
              "extensions" => [{
                "domain" => "example.com",
                "platform" => "canvas.instructure.com",
                "privacy_level" => "public",
                "settings" => {
                  "icon_url" => nil,
                  "placements" => [
                    {
                      "custom_fields" => { "foo" => "bar" },
                      "enabled" => true,
                      "icon_url" => "http://example.com/icon.png",
                      "message_type" => "LtiResourceLinkRequest",
                      "placement" => "global_navigation",
                      "target_link_uri" => "http://example.com/launch"
                    },
                    {
                      "custom_fields" => { "foo" => "bar" },
                      "enabled" => true,
                      "icon_url" => "http://example.com/icon.png",
                      "message_type" => "LtiResourceLinkRequest",
                      "placement" => "course_navigation",
                      "target_link_uri" => "http://example.com/launch"
                    }
                  ],
                  "platform" => "canvas.instructure.com",
                  "text" => "Example Tool"
                },
                "tool_id" => "Example Tool"
              }],
              "lti_version" => "1.3",
              "oidc_initiation_url" => "http://example.com/login",
              "platform" => "canvas.instructure.com",
              "privacy_level" => "public",
              "public_jwk_url" => "http://example.com/jwks",
              "scopes" => [],
              "target_link_uri" => nil,
              "title" => "Example Tool",
              "tool_id" => "Example Tool",
              "url" => nil,
              "settings" => {
                "course_navigation" => {
                  "custom_fields" => { "foo" => "bar" },
                  "enabled" => true,
                  "icon_url" => "http://example.com/icon.png",
                  "message_type" => "LtiResourceLinkRequest",
                  "placement" => "course_navigation",
                  "target_link_uri" => "http://example.com/launch"
                },
                "global_navigation" => {
                  "custom_fields" => { "foo" => "bar" },
                  "enabled" => true,
                  "icon_url" => "http://example.com/icon.png",
                  "message_type" => "LtiResourceLinkRequest",
                  "placement" => "global_navigation",
                  "target_link_uri" => "http://example.com/launch"
                },
                "icon_url" => nil,
                "placements" => [
                  {
                    "custom_fields" => { "foo" => "bar" },
                    "enabled" => true,
                    "icon_url" => "http://example.com/icon.png",
                    "message_type" => "LtiResourceLinkRequest",
                    "placement" => "global_navigation",
                    "target_link_uri" => "http://example.com/launch"
                  },
                  {
                    "custom_fields" => { "foo" => "bar" },
                    "enabled" => true,
                    "icon_url" => "http://example.com/icon.png",
                    "message_type" => "LtiResourceLinkRequest",
                    "placement" => "course_navigation",
                    "target_link_uri" => "http://example.com/launch"
                  }
                ],
                "platform" => "canvas.instructure.com",
                "text" => "Example Tool"
              },
            }
          )
        end
      end
    end
  end
end
