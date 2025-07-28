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
#

require_relative "../../lti_1_3_tool_configuration_spec_helper"

module Lti
  describe ToolConfiguration do
    include_context "lti_1_3_tool_configuration_spec_helper"

    let(:tool_configuration) do
      described_class.new(
        developer_key:,
        lti_registration:,
        disabled_placements:,
        privacy_level:,
        title:,
        description:,
        domain:,
        tool_id:,
        target_link_uri:,
        oidc_initiation_url:,
        oidc_initiation_urls:,
        public_jwk_url:,
        public_jwk:,
        custom_fields:,
        scopes:,
        redirect_uris:,
        launch_settings:,
        placements:
      )
    end
    let(:lti_registration) { developer_key.lti_registration }
    let(:disabled_placements) { [] }
    let(:privacy_level) { internal_lti_configuration[:privacy_level] }
    let(:title) { internal_lti_configuration[:title] }
    let(:description) { internal_lti_configuration[:description] }
    let(:domain) { internal_lti_configuration[:domain] }
    let(:tool_id) { internal_lti_configuration[:tool_id] }
    let(:target_link_uri) { internal_lti_configuration[:target_link_uri] }
    let(:oidc_initiation_url) { internal_lti_configuration[:oidc_initiation_url] }
    let(:oidc_initiation_urls) { internal_lti_configuration[:oidc_initiation_urls] }
    let(:public_jwk_url) { internal_lti_configuration[:public_jwk_url] }
    let(:public_jwk) { internal_lti_configuration[:public_jwk] }
    let(:custom_fields) { internal_lti_configuration[:custom_fields] }
    let(:scopes) { internal_lti_configuration[:scopes] }
    let(:redirect_uris) { internal_lti_configuration[:redirect_uris] }
    let(:launch_settings) { internal_lti_configuration[:launch_settings] }
    let(:placements) { internal_lti_configuration[:placements] }
    let(:developer_key) { DeveloperKey.create!(is_lti_key: true, public_jwk_url: "https://example.com", redirect_uris: ["https://example.com"]) }

    def make_placement(type, message_type, extra = {})
      {
        "target_link_uri" => "http://example.com/launch?placement=#{type}",
        "text" => "Test Title",
        "message_type" => message_type,
        "icon_url" => "https://static.thenounproject.com/png/131630-211.png",
        "placement" => type.to_s,
        **extra
      }
    end

    describe "validations" do
      subject do
        tool_configuration.save
      end

      context "when valid" do
        before do
          tool_configuration.disabled_placements = ["account_navigation"]
        end

        it { is_expected.to be true }

        context "with a description property at the submission_type_selection placement" do
          before do
            placements << make_placement(:submission_type_selection, "LtiDeepLinkingRequest")
          end

          it { is_expected.to be true }
        end

        context "with a require_resource_selection property at the submission_type_selection placement" do
          before do
            placements << make_placement(:submission_type_selection, "LtiDeepLinkingRequest", "require_resource_selection" => true)
          end

          it { is_expected.to be true }
        end
      end

      context "with non-matching schema" do
        context "a missing target_link_uri" do
          let(:target_link_uri) { nil }

          before do
            public_jwk["alg"] = "WRONG"
          end

          it { is_expected.to be false }

          it "contains a message about a missing target_link_uri" do
            tool_configuration.valid?
            error_msgs = tool_configuration.errors[:configuration]
            expect(error_msgs).to include(a_string_including("target_link_uri"))
          end

          it "contains a multiple error messages" do
            tool_configuration.valid?
            expect(tool_configuration.errors.size).to eq 2
          end
        end

        context "when the submission_type_selection description is longer than 255 characters" do
          before do
            placements << make_placement(:submission_type_selection, "LtiDeepLinkingRequest", "description" => "a" * 256)
          end

          it { is_expected.to be false }
        end

        context "when the submission_type_selection require_resource_selection is of the wrong type" do
          before do
            placements << make_placement(:submission_type_selection, "LtiDeepLinkingRequest", "require_resource_selection" => "true")
          end

          it { is_expected.to be false }
        end
      end

      context "when updating settings to use a non-matching schema" do
        it "causes a validation error and does not allow the update" do
          tool_configuration.save!
          expect do
            tool_configuration.update!(scopes: ["bogus"])
          end.to raise_error(ActiveRecord::RecordInvalid, /bogus/)
        end
      end

      context "when developer_key already has a tool_config" do
        before do
          lti_tool_configuration_model(developer_key:)
        end

        it { is_expected.to be false }
      end

      context 'when "developer_key_id" is blank' do
        before { tool_configuration.developer_key_id = nil }

        it { is_expected.to be false }
      end

      context "when title is blank" do
        let(:title) { nil }

        it { is_expected.to be false }
      end

      context 'when "disabled_placements" contains invalid placements' do
        before { tool_configuration.disabled_placements = ["invalid_placement", "account_navigation"] }

        it { is_expected.to be false }
      end

      context "when one of the configured placements has an unsupported message_type" do
        before do
          tool_configuration.placements = [
            {
              "placement" => "account_navigation",
              "message_type" => "LtiDeepLinkingRequest",
            }
          ]
        end

        it { is_expected.to be false }

        it "includes a friendly error message" do
          subject
          expect(tool_configuration.errors[:placements].first).to include("does not support message type")
        end
      end

      context "when public_jwk is not present" do
        let(:public_jwk) { {} }

        it { is_expected.to be true }
      end

      context "when public_jwk_url is not present" do
        let(:public_jwk_url) { nil }

        it { is_expected.to be true }
      end

      context "when public_jwk_url and public_jwk are not present" do
        let(:public_jwk) { {} }
        let(:public_jwk_url) { nil }

        it { is_expected.to be false }
      end

      context "when oidc_initiation_urls is not an hash" do
        let(:oidc_initiation_urls) { ["https://test.com"] }

        it { is_expected.to be false }
      end

      context "when oidc_initiation_urls values are not urls" do
        let(:oidc_initiation_urls) { { "us-east-1" => "@?!" } }

        it { is_expected.to be false }
      end

      context "when oidc_initiation_urls values are urls" do
        let(:oidc_initiation_urls) { { "us-east-1" => "http://example.com" } }

        it { is_expected.to be true }
      end
    end

    describe "after_update" do
      subject { tool_configuration.update!(changes) }

      before { tool_configuration.update!(developer_key:) }

      context "when a change to the configuration was made" do
        let(:changes) { { title: "new title!" } }

        it "calls update_external_tools! on the developer key" do
          expect(developer_key).to receive(:update_external_tools!)
          subject
        end
      end

      context "when a change to the configuration was not made" do
        let(:changes) { { disabled_placements: [] } }

        it "does not call update_external_tools! on the developer key" do
          expect(developer_key).not_to receive(:update_external_tools!)
          subject
        end
      end
    end

    describe "after_save" do
      let(:unified_tool_id) { "unified_tool_id_12345" }

      def run_after_save
        tool_configuration.save!
        run_jobs
      end

      it "calls the LearnPlatform::GlobalApi service and update the unified_tool_id attribute" do
        allow(LearnPlatform::GlobalApi).to receive(:get_unified_tool_id).and_return(unified_tool_id)
        run_after_save
        expect(LearnPlatform::GlobalApi).to have_received(:get_unified_tool_id).with(
          { lti_domain: domain,
            lti_name: title,
            lti_tool_id: tool_id,
            lti_url: target_link_uri,
            lti_version: "1.3" }
        )
        expect(tool_configuration.reload.unified_tool_id).to eq(unified_tool_id)
      end

      it "starts a background job to update the unified_tool_id" do
        expect do
          tool_configuration.save
        end.to change(Delayed::Job, :count).by(1)
      end

      context "when the configuration is already existing" do
        before do
          run_after_save
          allow(LearnPlatform::GlobalApi).to receive(:get_unified_tool_id)
        end

        context "when the configuration's settings changed" do
          before do
            tool_configuration.title = "new title"
          end

          it "calls the LearnPlatform::GlobalApi service" do
            run_after_save
            expect(LearnPlatform::GlobalApi).to have_received(:get_unified_tool_id)
          end
        end

        context "when the configuration's privacy_level changed" do
          before do
            tool_configuration.privacy_level = "email_only"
          end

          it "does not call the LearnPlatform::GlobalApi service" do
            run_after_save
            expect(LearnPlatform::GlobalApi).not_to have_received(:get_unified_tool_id)
          end
        end
      end
    end

    describe "#new_external_tool" do
      subject { tool_configuration.developer_key.lti_registration.new_external_tool(context) }

      shared_examples_for "a new context external tool" do
        context 'when "disabled_placements" is set' do
          before { tool_configuration.update!(disabled_placements: ["course_navigation"]) }

          it "does not set the disabled placements" do
            expect(subject.settings.keys).not_to include "course_navigation"
          end

          it "does set placements that are not disabled" do
            expect(subject.settings.keys).to include "account_navigation"
          end
        end

        context "placements in root of settings" do
          before do
            launch_settings["collaboration"] = {
              "message_type" => "LtiResourceLinkRequest",
              "canvas_icon_class" => "icon-lti",
              "icon_url" => "https://static.thenounproject.com/png/131630-211.png",
              "text" => "LTI 1.3 Test Tool Course Navigation",
              "target_link_uri" =>
              "http://lti13testtool.docker/launch?placement=collaboration",
              "enabled" => true
            }
            tool_configuration.save!
          end

          it "removes the placement" do
            expect(subject.settings.keys).not_to include "collaboration"
          end
        end

        context "when existing_tool is provided" do
          subject { tool_configuration.developer_key.lti_registration.new_external_tool(context, existing_tool:) }

          let(:existing_tool) { tool_configuration.developer_key.lti_registration.new_external_tool(context) }

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

        it "sets the correct workflow_state" do
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
          expect(subject.domain).to eq domain
        end

        it "uses the correct context" do
          expect(subject.context).to eq context
        end

        it "uses the correct description" do
          expect(subject.description).to eq description
        end

        it "uses the correct name" do
          expect(subject.name).to eq title
        end

        it "uses the correct top-level custom params" do
          expect(subject.custom_fields).to eq({ "has_expansion" => "$Canvas.user.id", "no_expansion" => "foo" })
        end

        it "uses the correct icon url" do
          expect(subject.icon_url).to eq launch_settings[:icon_url]
        end

        it "uses the correct selection height" do
          expect(subject.settings[:selection_height]).to eq launch_settings[:selection_height]
        end

        it "uses the correct selection width" do
          expect(subject.settings[:selection_width]).to eq launch_settings[:selection_width]
        end

        it "uses the correct text" do
          expect(subject.text).to eq launch_settings[:text]
        end

        it "sets the developer key" do
          expect(subject.developer_key).to eq developer_key
        end

        it "sets the lti_version" do
          expect(subject.lti_version).to eq "1.3"
        end

        context "placements" do
          subject { tool_configuration.developer_key.lti_registration.new_external_tool(context).settings["course_navigation"] }

          let(:placement_settings) { placements.first }

          it "uses the correct icon class" do
            expect(subject["canvas_icon_class"]).to eq placement_settings[:canvas_icon_class]
          end

          it "uses the correct icon url" do
            expect(subject["icon_url"]).to eq placement_settings[:icon_url]
          end

          it "uses the correct message type" do
            expect(subject["message_type"]).to eq placement_settings[:message_type]
          end

          it "uses the correct text" do
            expect(subject["text"]).to eq placement_settings[:text]
          end

          it "uses the correct target_link_uri" do
            expect(subject["target_link_uri"]).to eq placement_settings[:target_link_uri]
          end

          it "uses the correct value for enabled" do
            expect(subject["enabled"]).to eq placement_settings[:enabled]
          end

          it "uses the correct custom fields" do
            expect(subject["custom_fields"]).to eq placement_settings[:custom_fields]
          end
        end

        context "when the configuration has oidc_initiation_urls" do
          let(:oidc_initiation_urls) do
            {
              "us-east-1" => "http://www.example.com/initiate",
              "us-west-1" => "http://www.example.com/initiate2"
            }
          end

          before do
            tool_configuration.oidc_initiation_urls = oidc_initiation_urls
            tool_configuration.save!
          end

          subject { tool_configuration.developer_key.lti_registration.new_external_tool(context) }

          it "includes the oidc_initiation_urls in the new tool settings" do
            expect(subject.settings["oidc_initiation_urls"]).to eq oidc_initiation_urls
          end
        end
      end

      context "when context is a course" do
        it_behaves_like "a new context external tool" do
          let(:context) { course_model }
        end
      end

      context "when context is an account" do
        it_behaves_like "a new context external tool" do
          let(:context) { account_model }
        end
      end
    end

    describe "verify_placements" do
      subject { tool_configuration.verify_placements }

      before do
        tool_configuration.save!
      end

      %w[submission_type_selection top_navigation].each do |placement|
        it "returns nil when there are no #{placement} placements" do
          expect(subject).to be_nil
        end

        context "when the configuration has a #{placement} placement" do
          let(:tool_configuration) do
            super().tap do |tc|
              tc.placements << make_placement(placement, "LtiResourceLinkRequest")
            end
          end

          it { is_expected.to include("Warning").and include(placement) }

          context "when the tool is allowed to use the #{placement} placement through it's dev key" do
            before do
              Setting.set("#{placement}_allowed_dev_keys", tool_configuration.developer_key.global_id.to_s)
            end

            it { is_expected.to be_nil }
          end

          context "when the tool is allowed to use the #{placement} placement through it's domain" do
            before do
              Setting.set("#{placement}_allowed_launch_domains", tool_configuration.domain)
            end

            it { is_expected.to be_nil }
          end

          context "when the tool has no domain and domain list is containing an empty space" do
            before do
              allow(tool_configuration).to receive_messages(domain: "", developer_key_id: nil)
              Setting.set("#{placement}_allowed_launch_domains", ", ,,")
              Setting.set("#{placement}_allowed_dev_keys", ", ,,")
            end

            it { is_expected.to include("Warning").and include(placement) }
          end
        end
      end
    end

    describe "placement_warnings" do
      subject { tool_configuration.placement_warnings }
      context "when the tool does not have resource_selection placement" do
        it "is empty" do
          expect(subject).to eq []
        end
      end

      context "when the tool has resource_selection placement" do
        before do
          placements << make_placement(:resource_selection, "LtiResourceLinkRequest")
        end

        it "contains a warning message about deprecation" do
          expect(subject[0]).to include("Warning").and include("deprecated").and include("resource_selection")
        end
      end

      context "when the tool has submission_type_selection placement" do
        before do
          placements << make_placement(:submission_type_selection, "LtiResourceLinkRequest")
        end

        it "contains a warning message about approved LTI tools" do
          expect(subject[0]).to include("Warning").and include("submission_type_selection")
        end
      end
    end

    describe "#configuration_changed?" do
      subject { tool_configuration.send :configuration_changed? }

      it { is_expected.to be false }

      context "when settings have changed" do
        before do
          tool_configuration.launch_settings["selection_height"] = 100
          tool_configuration.save!
        end

        it { is_expected.to be true }
      end

      context "when any config fields have changed" do
        before do
          tool_configuration.title = "new title"
          tool_configuration.save!
        end

        it { is_expected.to be true }
      end
    end

    describe "#set_redirect_uris" do
      subject { tool_configuration.send :set_redirect_uris }

      context "with redirect_uris" do
        before do
          tool_configuration.redirect_uris = ["http://example.com"]
        end

        it "does not set redirect_uris" do
          expect { subject }.not_to change { tool_configuration.redirect_uris }
        end
      end

      context "without redirect_uris" do
        it "sets redirect_uris to default" do
          subject
          expect(tool_configuration.redirect_uris).to eq [tool_configuration.target_link_uri]
        end
      end
    end
  end
end
