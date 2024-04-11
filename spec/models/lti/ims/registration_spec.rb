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

      it "should return a correct configuration" do
        expect(subject).to eq(
          {
            "custom_fields" => nil,
            "description" => nil,
            "extensions" => [{
              "domain" => "example.com",
              "platform" => "canvas.instructure.com",
              "privacy_level" => "anonymous",
              "settings" => {
                "icon_url" => nil,
                "placements" => [],
                "platform" => "canvas.instructure.com",
                "text" => "Example Tool",
              },
              "tool_id" => "Example Tool"
            }],
            "oidc_initiation_url" => "http://example.com/login",
            "privacy_level" => "anonymous",
            "public_jwk_url" => "http://example.com/jwks",
            "scopes" => [],
            "target_link_uri" => nil,
            "title" => "Example Tool",
            "url" => nil,
          }
        )
      end

      context "a placement isn't defined" do
        let(:lti_tool_configuration) do
          {
            domain: "example.com",
            messages: [
              {
                type: "LtiResourceLinkRequest",
                target_link_uri: "http://example.com/launch",
                placements: ["link_selection"]
              },
              {
                type: "LtiDeepLinkingRequest",
                target_link_uri: "http://example.com/deep_linking",
              }
            ],
            claims: []
          }
        end

        it "defaults to link_selection" do
          expect(subject["extensions"][0][:settings][:placements]).to eq(
            [
              {
                "enabled" => true,
                "message_type" => "LtiResourceLinkRequest",
                "placement" => "link_selection",
                "target_link_uri" => "http://example.com/launch"
              }
            ]
          )
        end

        context "when multiple are defined" do
          let(:lti_tool_configuration) do
            {
              domain: "example.com",
              messages: [
                {
                  type: "LtiResourceLinkRequest",
                  target_link_uri: "http://example.com/launch",
                  placements: ["link_selection", "global_navigation"]
                },
                {
                  type: "LtiResourceLinkRequest",
                  target_link_uri: "http://example.com/launch_another_one",
                  placements: %w[link_selection global_navigation assignment_menu]
                },
                {
                  type: "LtiDeepLinkingRequest",
                  target_link_uri: "http://example.com/deep_linking",
                  placements: %w[link_selection homework_submission assignment_menu]
                }
              ],
              claims: []
            }
          end

          it "should choose the first placement" do
            expect(subject["extensions"][0][:settings][:placements]).to eq(
              [
                {
                  "enabled" => true,
                  "message_type" => "LtiResourceLinkRequest",
                  "placement" => "link_selection",
                  "target_link_uri" => "http://example.com/launch"
                },
                {
                  "enabled" => true,
                  "message_type" => "LtiResourceLinkRequest",
                  "placement" => "global_navigation",
                  "target_link_uri" => "http://example.com/launch"
                },
                {
                  "enabled" => true,
                  "message_type" => "LtiResourceLinkRequest",
                  "placement" => "assignment_menu",
                  "target_link_uri" => "http://example.com/launch_another_one"
                },
                {
                  "enabled" => true,
                  "message_type" => "LtiDeepLinkingRequest",
                  "placement" => "homework_submission",
                  "target_link_uri" => "http://example.com/deep_linking"
                }
              ]
            )
          end
        end
      end

      context "privacy level isn't defined" do
        let(:lti_tool_configuration) do
          {
            domain: "example.com",
            messages: [],
            claims: []
          }
        end

        it "privacy level defaults to anonymous" do
          expect(subject[:privacy_level]).to eq("anonymous")
        end

        context "when claims is an Email Address" do
          before do
            lti_tool_configuration[:claims] = %w[email]
          end

          it "privacy level is User's email Only" do
            expect(subject[:privacy_level]).to eq("email_only")
          end
        end

        context "when claims are Name, First Name, Last Name, Avatar" do
          before do
            lti_tool_configuration[:claims] = %w[name given_name family_name]
          end

          it "privacy level is User's Name Only" do
            expect(subject[:privacy_level]).to eq("name_only")
          end
        end

        context "when claims are Name, First Name, Last Name, SIS ID, Avatar, Email Address" do
          before do
            lti_tool_configuration[:claims] = %w[name given_name family_name picture email https://purl.imsglobal.org/spec/lti/claim/lis]
          end

          it "privacy level is public" do
            expect(subject[:privacy_level]).to eq("public")
          end
        end

        context "when claims are Email and Avatar" do
          before do
            lti_tool_configuration[:claims] = %w[email picture]
          end

          it "privacy level is public" do
            expect(subject[:privacy_level]).to eq("public")
          end
        end

        context "when claims are Email and Name" do
          before do
            lti_tool_configuration[:claims] = %w[email name]
          end

          it "privacy level is public" do
            expect(subject[:privacy_level]).to eq("public")
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
              "https://canvas.instructure.com/lti/launch_width": "200",
              "https://canvas.instructure.com/lti/launch_height": "300",
              "https://canvas.instructure.com/lti/display_type": "full_width",
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
          let(:canvas_placement_hash) do
            {
              custom_fields: { "foo" => "bar" },
              enabled: true,
              icon_url: "http://example.com/icon.png",
              message_type: "LtiResourceLinkRequest",
              target_link_uri: "http://example.com/launch",
              display_type: "full_width",
            }
          end

          it "accepts valid placements" do
            expect(subject).to eq [
              canvas_placement_hash.merge(placement: "assignment_edit", launch_width: 200, launch_height: 300),
              canvas_placement_hash.merge(placement: "global_navigation", selection_width: 200, selection_height: 300),
              canvas_placement_hash.merge(placement: "course_navigation", selection_width: 200, selection_height: 300),
              canvas_placement_hash.merge(placement: "link_selection", selection_width: 200, selection_height: 300),
              canvas_placement_hash.merge(placement: "editor_button", selection_width: 200, selection_height: 300),
            ]
          end

          it "sets windowTarget if display_type is new_window" do
            message = registration.lti_tool_configuration["messages"].first
            message["https://canvas.instructure.com/lti/display_type"] = "new_window"
            expect(subject.first).to include({ windowTarget: "_blank", display_type: "default" })
          end

          it "rejects invalid placements" do
            bad_placement_name = "course_navigationhttps://canvas.instructure.com/lti/"
            registration.lti_tool_configuration["messages"].first["placements"] << bad_placement_name
            expect { registration.save! }.to raise_error(ActiveRecord::RecordInvalid)
          end

          it "doesn't include the default_enabled param if it's not present" do
            expect(subject.count { |p| p[:default].present? }).to be(0)
          end

          it "doesn't include the default_enabled param if it's set to true" do
            lti_tool_configuration[:messages].first[Registration::COURSE_NAV_DEFAULT_ENABLED_EXTENSION] = true
            expect(subject.count { |p| p[:default].present? }).to be(0)
          end

          it "includes the default_enabled param only for the course_navigation placement" do
            lti_tool_configuration[:messages].first[Registration::COURSE_NAV_DEFAULT_ENABLED_EXTENSION] = false
            expect(subject.find { |p| p[:placement] == "course_navigation" }).to eq(canvas_placement_hash.merge(placement: "course_navigation", default: "disabled", selection_width: 200, selection_height: 300))
            expect(subject.count { |p| p[:default] == "disabled" }).to be(1)
          end
        end
      end

      describe "when extension visibility is supplied" do
        let(:lti_tool_configuration) do
          {
            domain: "example.com",
            messages: [{
              type: "LtiResourceLinkRequest",
              target_link_uri: "http://example.com/launch",
              placements: ["global_navigation"],
              "https://canvas.instructure.com/lti/visibility": "admins",
            }],
          }
        end

        subject { registration.canvas_configuration["extensions"][0]["settings"]["placements"][0]["visibility"] }

        it "set visibility in the canvas configuration" do
          expect(subject).to eq("admins")
        end
      end

      describe "when an invalid extension visibility is supplied" do
        let(:lti_tool_configuration) do
          {
            domain: "example.com",
            messages: [{
              type: "LtiResourceLinkRequest",
              target_link_uri: "http://example.com/launch",
              placements: ["global_navigation"],
              "https://canvas.instructure.com/lti/visibility": "foo",
            }],
          }
        end

        subject { registration.canvas_configuration["extensions"][0]["settings"]["placements"][0]["visibility"] }

        it "ignores the invalid visibility value" do
          expect(subject).to be_nil
        end
      end

      describe "importable_configuration" do
        subject { registration.importable_configuration }
        let(:lti_tool_configuration) do
          {
            domain: "example.com",
            custom_parameters: {
              "global_foo" => "global_bar"
            },
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

        it "should return a correct configuration" do
          expect(subject).to eq(
            {
              "custom_fields" => {
                "global_foo" => "global_bar"
              },
              "description" => nil,
              "domain" => "example.com",
              "extensions" => [{
                "domain" => "example.com",
                "platform" => "canvas.instructure.com",
                "privacy_level" => "anonymous",
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
              "privacy_level" => "anonymous",
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
