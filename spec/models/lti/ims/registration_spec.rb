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
    let(:redirect_uris) { ["http://example.com"] }
    let(:initiate_login_uri) { "http://example.com/login" }
    let(:client_name) { "Example Tool" }
    let(:jwks_uri) { "http://example.com/jwks" }
    let(:logo_uri) { "http://example.com/logo.png" }
    let(:client_uri) { "http://example.com/" }
    let(:tos_uri) { "http://example.com/tos" }
    let(:policy_uri) { "http://example.com/policy" }
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
        redirect_uris:,
        initiate_login_uri:,
        client_name:,
        jwks_uri:,
        logo_uri:,
        client_uri:,
        tos_uri:,
        policy_uri:,
        lti_tool_configuration:,
        scopes:
      }.compact)
      r.developer_key = developer_key
      r
    end
    let(:developer_key) { DeveloperKey.create }

    it "is soft_deleted when destroy is called" do
      registration.destroy
      expect(registration.reload.workflow_state).to eq("deleted")
    end

    describe "associations" do
      subject { Lti::IMS::Registration.new }
      it { is_expected.to belong_to(:lti_registration).class_name("Lti::Registration") }
      it { is_expected.to belong_to(:developer_key).inverse_of(:ims_registration).optional(false) }
    end

    describe "validations" do
      subject { registration.validate }

      context "when valid" do
        it { is_expected.to be true }
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
                "icon_url" => registration.logo_uri,
                "placements" => [],
                "platform" => "canvas.instructure.com",
                "text" => "Example Tool",
              },
              "tool_id" => nil
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

          it "prefers the default_enabled value from the overlay" do
            lti_tool_configuration[:messages].first[Registration::COURSE_NAV_DEFAULT_ENABLED_EXTENSION] = true
            registration.registration_overlay["placements"] = [{ "type" => "course_navigation", "default" => "disabled" }]

            expect(subject.find { |p| p[:placement] == "course_navigation" }[:default]).to eq("disabled")
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

      describe "when a tool_id is not supplied" do
        let(:lti_tool_configuration) do
          {
            domain: "example.com",
            messages: [],
            claims: []
          }
        end

        subject { registration.canvas_configuration["extensions"][0]["tool_id"] }

        it "it is nil" do
          expect(subject).to be_nil
        end
      end

      describe "when a tool_id is supplied" do
        let(:lti_tool_configuration) do
          {
            domain: "example.com",
            messages: [],
            claims: [],
            "https://canvas.instructure.com/lti/tool_id": "ToolV2"
          }
        end

        subject { registration.canvas_configuration["extensions"][0]["tool_id"] }

        it "it is extracted from the claim" do
          expect(subject).to eq "ToolV2"
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
                  "icon_url" => registration.logo_uri,
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
                "tool_id" => nil
              }],
              "lti_version" => "1.3",
              "oidc_initiation_url" => "http://example.com/login",
              "platform" => "canvas.instructure.com",
              "privacy_level" => "anonymous",
              "public_jwk_url" => "http://example.com/jwks",
              "scopes" => [],
              "target_link_uri" => nil,
              "title" => "Example Tool",
              "tool_id" => nil,
              "unified_tool_id" => nil,
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
                "icon_url" => registration.logo_uri,
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

    describe "#new_external_tool" do
      subject { registration.new_external_tool(context) }

      let(:lti_tool_configuration) do
        {
          :domain => "example.com",
          :messages => [
            {
              type: "LtiResourceLinkRequest",
              target_link_uri:,
              placements: ["course_navigation", "account_navigation"],
              icon_uri:,
              label:,
              custom_parameters:
            }
          ],
          :claims => [],
          :target_link_uri => target_link_uri,
          :description => description,
          :custom_parameters => custom_parameters,
          :icon_uri => icon_uri,
          Lti::IMS::Registration::PRIVACY_LEVEL_EXTENSION => privacy_level
        }
      end
      let(:privacy_level) { "public" }
      let(:target_link_uri) { "http://example.com/launch" }
      let(:description) { "Example Tool" }
      let(:custom_parameters) { { "has_expansion" => "$Canvas.user.id", "no_expansion" => "foo" } }
      let(:icon_uri) { "http://example.com/icon.png" }
      let(:label) { "Course Navigation" }

      let(:context) { account_model }

      context 'when "disabled_placements" is set' do
        before { registration.registration_overlay["disabledPlacements"] = ["course_navigation"] }

        it "does not set the disabled placements" do
          expect(subject.settings.keys).not_to include "course_navigation"
        end

        it "does set placements that are not disabled" do
          expect(subject.settings.keys).to include "account_navigation"
        end
      end

      context "when no privacy level is set" do
        let(:privacy_level) { nil }

        it 'sets the workflow_state to "anonymous"' do
          expect(subject.workflow_state).to eq "anonymous"
        end
      end

      context "when existing_tool is provided" do
        subject { registration.new_external_tool(context, existing_tool:) }

        let(:existing_tool) { registration.new_external_tool(context) }

        context "and existing tool is disabled" do
          let(:state) { "disabled" }

          before do
            existing_tool.update!(workflow_state: state)
          end

          it "uses the existing workflow_state" do
            expect(subject.workflow_state).to eq state
          end
        end

        context "and tool state is different from configuration state" do
          let(:state) { "anonymous" }

          before do
            existing_tool.update!(workflow_state: state)
          end

          it "overwrites existing workflow_state" do
            expect(subject.workflow_state).to eq privacy_level
          end
        end
      end

      it "sets the correct default workflow_state" do
        expect(subject.workflow_state).to eq "public"
      end

      it "sets the correct placements" do
        expect(subject.settings.keys).to include "account_navigation"
        expect(subject.settings.keys).to include "course_navigation"
      end

      it "uses the correct launch url" do
        expect(subject.url).to eq target_link_uri
      end

      it "uses the correct domain" do
        expect(subject.domain).to eq lti_tool_configuration[:domain]
      end

      it "uses the correct context" do
        expect(subject.context).to eq context
      end

      it "uses the correct description" do
        expect(subject.description).to eq description
      end

      it "uses the correct name" do
        expect(subject.name).to eq client_name
      end

      it "uses the correct top-level custom params" do
        expect(subject.custom_fields).to eq custom_parameters
      end

      it "uses the correct icon url" do
        expect(subject.icon_url).to eq logo_uri
      end

      it "uses the correct text" do
        expect(subject.text).to eq client_name
      end

      it "sets the developer key" do
        expect(subject.developer_key).to eq developer_key
      end

      it "sets the lti_version" do
        expect(subject.lti_version).to eq "1.3"
      end

      context "when registration has unified_tool_id" do
        let(:unified_tool_id) { "tool_id" }

        before do
          registration.unified_tool_id = unified_tool_id
        end

        it "sets the unified_tool_id" do
          expect(subject.unified_tool_id).to eq unified_tool_id
        end
      end

      context "placements" do
        subject { registration.new_external_tool(context).settings["course_navigation"] }

        it "uses the correct icon url" do
          expect(subject["icon_url"]).to eq icon_uri
        end

        it "uses the correct message type" do
          expect(subject["message_type"]).to eq "LtiResourceLinkRequest"
        end

        it "uses the correct text" do
          expect(subject["text"]).to eq label
        end

        it "uses the correct target_link_uri" do
          expect(subject["target_link_uri"]).to eq target_link_uri
        end

        it "uses the correct value for enabled" do
          expect(subject["enabled"]).to be true
        end

        it "uses the correct custom fields" do
          expect(subject["custom_fields"]).to eq custom_parameters
        end
      end
    end

    describe "registration_configuration" do
      subject { registration.registration_configuration }

      context "when no explicit tool_id is set" do
        it "formats the configuration correctly with tool_id being nil" do
          config = registration.lti_tool_configuration.with_indifferent_access
          expect(subject).to eq(
            {
              name: registration.client_name,
              description: config[:description],
              domain: config[:domain],
              custom_fields: config[:custom_parameters],
              target_link_uri: config[:target_link_uri],
              privacy_level: registration.privacy_level,
              icon_url: registration.logo_uri,
              oidc_initiation_url: registration.initiate_login_uri,
              redirect_uris: registration.redirect_uris,
              public_jwk_url: registration.jwks_uri,
              scopes: registration.overlaid_scopes,
              placements: registration.placements,
              tool_id: nil
            }.with_indifferent_access
          )
        end
      end

      context "when an explicit tool_id is set" do
        let(:lti_tool_configuration) do
          {
            domain: "example.com",
            messages: [],
            claims: [],
            "https://canvas.instructure.com/lti/tool_id": "ToolV2"
          }
        end

        it "formats the configuration correctly with tool_id" do
          config = registration.lti_tool_configuration.with_indifferent_access
          expect(subject).to eq(
            {
              name: registration.client_name,
              description: config[:description],
              domain: config[:domain],
              custom_fields: config[:custom_parameters],
              target_link_uri: config[:target_link_uri],
              privacy_level: registration.privacy_level,
              icon_url: registration.logo_uri,
              oidc_initiation_url: registration.initiate_login_uri,
              redirect_uris: registration.redirect_uris,
              public_jwk_url: registration.jwks_uri,
              scopes: registration.overlaid_scopes,
              placements: registration.placements,
              tool_id: "ToolV2"
            }.with_indifferent_access
          )
        end
      end
    end

    describe "as_json" do
      subject { registration.as_json }

      it "includes the correct attributes" do
        expect(subject.keys).to eq(
          %w[
            id
            lti_registration_id
            developer_key_id
            overlay
            lti_tool_configuration
            application_type
            grant_types
            response_types
            redirect_uris
            initiate_login_uri
            client_name
            jwks_uri
            logo_uri
            token_endpoint_auth_method
            contacts
            client_uri
            policy_uri
            tos_uri
            scopes
            created_at
            updated_at
            guid
            tool_configuration
            default_configuration
          ]
        )
      end
    end
  end
end
