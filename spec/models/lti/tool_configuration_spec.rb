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

require_relative "../../lti_1_3_spec_helper"

module Lti
  describe ToolConfiguration do
    include_context "lti_1_3_spec_helper"

    let(:public_jwk) do
      {
        "kty" => "RSA",
        "e" => "AQAB",
        "n" => "2YGluUtCi62Ww_TWB38OE6wTaN...",
        "kid" => "2018-09-18T21:55:18Z",
        "alg" => "RS256",
        "use" => "sig"
      }
    end
    let(:tool_configuration) do
      described_class.new(settings:).tap do |tc|
        tc.developer_key = developer_key
        tc.redirect_uris = ["https://example.com"]
        tc.send :normalize_configuration
        tc.transform_settings
      end
    end
    let(:untransformed_tool_configuration) do
      described_class.new(settings:).tap do |tc|
        tc.developer_key = developer_key
      end
    end
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
      subject { tool_configuration.save }

      context "when valid" do
        before do
          tool_configuration.disabled_placements = ["account_navigation"]
        end

        it { is_expected.to be true }

        context "with a description property at the submission_type_selection placement" do
          let(:settings) do
            super().tap do |res|
              res["extensions"].first["settings"]["placements"] << make_placement(
                :submission_type_selection,
                "LtiDeepLinkingRequest",
                "description" => "Test Description"
              )
            end
          end

          it { is_expected.to be true }
        end

        context "with a require_resource_selection property at the submission_type_selection placement" do
          let(:settings) do
            super().tap do |res|
              res["extensions"].first["settings"]["placements"] << make_placement(
                :submission_type_selection,
                "LtiDeepLinkingRequest",
                "require_resource_selection" => true
              )
            end
          end

          it { is_expected.to be true }
        end
      end

      context "with non-matching schema" do
        context "a missing target_link_uri" do
          let(:settings) do
            s = super()
            s.delete("target_link_uri")
            s
          end

          it { is_expected.to be false }

          it "contains a message about a missing target_link_uri" do
            tool_configuration.valid?
            expect(tool_configuration.errors[:configuration].first.message).to include("target_link_uri,")
          end
        end

        context "when the submission_type_selection description is longer than 255 characters" do
          let(:settings) do
            super().tap do |s|
              s["extensions"].first["settings"]["placements"] << make_placement(
                :submission_type_selection,
                "LtiDeepLinkingRequest",
                "description" => "a" * 256
              )
            end
          end

          it { is_expected.to be false }
        end

        context "when the submission_type_selection require_resource_selection is of the wrong type" do
          let(:settings) do
            super().tap do |s|
              s["extensions"].first["settings"]["placements"] << make_placement(
                :submission_type_selection,
                "LtiDeepLinkingRequest",
                "require_resource_selection" => "true"
              )
            end
          end

          it { is_expected.to be false }
        end
      end

      context "when updating settings to use a non-matching schema" do
        it "causes a validation error and does not allow the update" do
          tool_configuration.save!
          settings = tool_configuration.settings.merge("scopes" => ["bogus"])
          expect do
            tool_configuration.update!(settings:)
          end.to raise_error(ActiveRecord::RecordInvalid, /bogus/)
        end
      end

      context "when developer_key already has a tool_config" do
        before do
          described_class.create! settings:, developer_key:
        end

        it { is_expected.to be false }
      end

      context 'when "developer_key_id" is blank' do
        before { tool_configuration.developer_key_id = nil }

        it { is_expected.to be false }
      end

      context "when the settings are invalid" do
        context "when no URL or domain is set" do
          before do
            settings.delete("target_link_uri")
            settings["extensions"].first.delete("domain")
            settings["extensions"].first.delete("target_link_uri")
            settings["extensions"].first["settings"]["placements"].first.delete("target_link_uri")
          end

          it { is_expected.to be false }
        end

        context "when name is blank" do
          before { settings.delete("title") }

          it { is_expected.to be false }
        end
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
          expect(tool_configuration.errors[:placements].first.message).to include("does not support message type")
        end
      end

      context "when extensions have non-Canvas platform" do
        let(:settings) do
          sets = super()
          sets["extensions"].first["platform"] = "blackboard.bb.com"
          sets
        end

        it { is_expected.to be true }
      end

      context "when public_jwk is not present" do
        let(:settings) do
          s = super()
          s.delete("public_jwk")
          s["public_jwk_url"] = "https://test.com"
          s
        end

        it { is_expected.to be true }
      end

      context "when public_jwk_url is not present" do
        let(:settings) do
          s = super()
          s.delete("public_jwk_url")
          s["public_jwk"] = public_jwk
          s
        end

        it { is_expected.to be true }
      end

      context "when public_jwk_url and public_jwk are not present" do
        let(:settings) do
          s = super()
          s.delete("public_jwk_url")
          s.delete("public_jwk")
          s
        end

        it { is_expected.to be false }
      end

      context "when oidc_initiation_urls is not an hash" do
        let(:settings) { super().tap { |s| s["oidc_initiation_urls"] = ["https://test.com"] } }

        it { is_expected.to be false }
      end

      context "when oidc_initiation_urls values are not urls" do
        let(:settings) { super().tap { |s| s["oidc_initiation_urls"] = { "us-east-1" => "@?!" } } }

        it { is_expected.to be false }
      end

      context "when oidc_initiation_urls values are urls" do
        let(:settings) { super().tap { |s| s["oidc_initiation_urls"] = { "us-east-1" => "http://example.com" } } }

        it { is_expected.to be true }
      end

      context "when settings is a JSON string" do
        let(:settings) { super().to_json }

        it { is_expected.to be true }
      end

      context "when settings is an invalid JSON string" do
        let(:settings) { "hello world!" }

        it { is_expected.to be false }
      end
    end

    describe "before_update" do
      subject { tool_configuration.update!(changes) }

      let(:tool_configuration) { untransformed_tool_configuration }

      before { tool_configuration.update!(developer_key:) }

      context "when root privacy_level is updated to nil but settings not changed" do
        let(:changes) { { disabled_placements: [], privacy_level: nil } }

        it "keeps the privacy_level value from extensions and not updates to nil" do
          expect { subject }.not_to change { tool_configuration[:privacy_level] }
        end
      end
    end

    describe "after_update" do
      subject { tool_configuration.update!(changes) }

      before { tool_configuration.update!(developer_key:) }

      context "when a change to the settings hash was made" do
        let(:changed_settings) do
          s = settings
          s["title"] = "new title!"
          s
        end
        let(:changes) { { settings: changed_settings } }

        it "calls update_external_tools! on the developer key" do
          expect(developer_key).to receive(:update_external_tools!)
          subject
        end
      end

      context "when a change to the settings hash was not made" do
        let(:changes) { { disabled_placements: [] } }

        it "does not call update_external_tools! on the developer key" do
          expect(developer_key).not_to receive(:update_external_tools!)
          subject
        end
      end
    end

    describe "after_save" do
      let(:unified_tool_id) { "unified_tool_id_12345" }

      subject { tool_configuration }

      context "update_unified_tool_id FF is on" do
        before do
          tool_configuration.developer_key.root_account.enable_feature!(:update_unified_tool_id)
        end

        it "calls the LearnPlatform::GlobalApi service and update the unified_tool_id attribute" do
          allow(LearnPlatform::GlobalApi).to receive(:get_unified_tool_id).and_return(unified_tool_id)
          subject.save
          run_jobs
          expect(LearnPlatform::GlobalApi).to have_received(:get_unified_tool_id).with(
            { lti_domain: settings["extensions"].first["domain"],
              lti_name: settings["title"],
              lti_tool_id: settings["extensions"].first["tool_id"],
              lti_url: settings["target_link_uri"],
              lti_version: "1.3" }
          )
          tool_configuration.reload
          expect(tool_configuration.unified_tool_id).to eq(unified_tool_id)
        end

        it "starts a background job to update the unified_tool_id" do
          expect do
            subject.save
          end.to change(Delayed::Job, :count).by(1)
        end

        context "when the configuration is already existing" do
          before do
            subject.save
            run_jobs
          end

          context "when the configuration's settings changed" do
            it "calls the LearnPlatform::GlobalApi service" do
              allow(LearnPlatform::GlobalApi).to receive(:get_unified_tool_id)
              subject.title = "new title"
              subject.save
              run_jobs
              expect(LearnPlatform::GlobalApi).to have_received(:get_unified_tool_id)
            end
          end

          context "when the configuration's privacy_level changed" do
            it "does not call the LearnPlatform::GlobalApi service" do
              allow(LearnPlatform::GlobalApi).to receive(:get_unified_tool_id)
              subject.privacy_level = "new privacy_level"
              subject.save
              run_jobs
              expect(LearnPlatform::GlobalApi).not_to have_received(:get_unified_tool_id)
            end
          end
        end
      end

      context "update_unified_tool_id FF is off" do
        before do
          tool_configuration.developer_key.root_account.disable_feature!(:update_unified_tool_id)
        end

        it "does not call the LearnPlatform::GlobalApi service" do
          allow(LearnPlatform::GlobalApi).to receive(:get_unified_tool_id)
          subject
          run_jobs
          expect(LearnPlatform::GlobalApi).not_to have_received(:get_unified_tool_id)
        end
      end
    end

    describe "#new_external_tool" do
      subject { tool_configuration.developer_key.lti_registration.new_external_tool(context) }

      let(:extensions) { settings["extensions"].first }

      before do
        extensions["privacy_level"] = "public"
      end

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
          let(:settings) do
            s = super()
            s["extensions"].first["settings"]["collaboration"] = {
              "message_type" => "LtiResourceLinkRequest",
              "canvas_icon_class" => "icon-lti",
              "icon_url" => "https://static.thenounproject.com/png/131630-211.png",
              "text" => "LTI 1.3 Test Tool Course Navigation",
              "target_link_uri" =>
              "http://lti13testtool.docker/launch?placement=collaboration",
              "enabled" => true
            }
            s
          end

          it "removes the placement" do
            expect(subject.settings.keys).not_to include "collaboration"
          end
        end

        context "when no privacy level is set" do
          before { extensions["privacy_level"] = nil }

          it 'sets the workflow_state to "anonymous"' do
            expect(subject.workflow_state).to eq "anonymous"
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
              expect(subject.workflow_state).to eq extensions["privacy_level"]
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
          expect(subject.url).to eq settings["target_link_uri"]
        end

        it "uses the correct domain" do
          expect(subject.domain).to eq extensions["domain"]
        end

        it "uses the correct context" do
          expect(subject.context).to eq context
        end

        it "uses the correct description" do
          expect(subject.description).to eq settings["description"]
        end

        it "uses the correct name" do
          expect(subject.name).to eq settings["title"]
        end

        it "uses the correct top-level custom params" do
          expect(subject.custom_fields).to eq({ "has_expansion" => "$Canvas.user.id", "no_expansion" => "foo" })
        end

        it "uses the correct icon url" do
          expect(subject.icon_url).to eq extensions.dig("settings", "icon_url")
        end

        it "uses the correct selection height" do
          expect(subject.settings[:selection_height]).to eq extensions.dig("settings", "selection_height")
        end

        it "uses the correct selection width" do
          expect(subject.settings[:selection_width]).to eq extensions.dig("settings", "selection_width")
        end

        it "uses the correct text" do
          expect(subject.text).to eq extensions.dig("settings", "text")
        end

        it "sets the developer key" do
          expect(subject.developer_key).to eq developer_key
        end

        it "sets the lti_version" do
          expect(subject.lti_version).to eq "1.3"
        end

        context "placements" do
          subject { tool_configuration.developer_key.lti_registration.new_external_tool(context).settings["course_navigation"] }

          let(:placement_settings) { extensions["settings"]["placements"].first }

          it "uses the correct icon class" do
            expect(subject["canvas_icon_class"]).to eq placement_settings["canvas_icon_class"]
          end

          it "uses the correct icon url" do
            expect(subject["icon_url"]).to eq placement_settings["icon_url"]
          end

          it "uses the correct message type" do
            expect(subject["message_type"]).to eq placement_settings["message_type"]
          end

          it "uses the correct text" do
            expect(subject["text"]).to eq placement_settings["text"]
          end

          it "uses the correct target_link_uri" do
            expect(subject["target_link_uri"]).to eq placement_settings["target_link_uri"]
          end

          it "uses the correct value for enabled" do
            expect(subject["enabled"]).to eq placement_settings["enabled"]
          end

          it "uses the correct custom fields" do
            expect(subject["custom_fields"]).to eq placement_settings["custom_fields"]
          end
        end

        context "with non-canvas extensions in settings" do
          subject { tool_configuration.developer_key.lti_registration.new_external_tool(context) }

          let(:settings) do
            sets = super()
            sets["extensions"].first["platform"] = "blackboard.bb.com"
            sets
          end

          it "does not include any placements defined for non-canvas platform" do
            Lti::ResourcePlacement::PLACEMENTS.each do |p|
              expect(subject.settings[p]).to be_blank
            end
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

    describe "#create_tool_config_and_key!" do
      let_once(:account) { Account.create! }
      let(:params) do
        {
          settings: settings.with_indifferent_access,
          privacy_level: "public"
        }
      end
      let(:tool_configuration) { described_class.create_tool_config_and_key!(account, params) }
      let(:scopes) { ["https://purl.imsglobal.org/spec/lti-ags/scope/lineitem"] }

      it "creates a dev key" do
        expect { described_class.create_tool_config_and_key! account, params }.to change(DeveloperKey, :count).by(1)
      end

      it "adds scopes to dev key" do
        expect(tool_configuration.developer_key.scopes).to eq(settings["scopes"])
      end

      it "set `target_link_uri` to developer_key.redirect_uris" do
        expect(tool_configuration.developer_key.redirect_uris.size).to eq 1
        expect(tool_configuration.developer_key.redirect_uris.first).to eq settings["target_link_uri"]
      end

      context "with extra custom fields provided" do
        let(:params) { super().merge(custom_fields: "foo=bar") }

        it "merges all custom fields" do
          expect(tool_configuration.settings["custom_fields"]).to eq settings["custom_fields"].merge({ "foo" => "bar" })
        end
      end

      context "when scopes is nil" do
        let(:settings) { super().except("scopes", :scopes) }

        it "sets scopes to []" do
          expect(tool_configuration.scopes).to eq []
          expect(tool_configuration.developer_key.scopes).to eq []
        end
      end

      context "with provided redirect_uris" do
        let(:redirect_uris) { [settings["target_link_uri"], "http://example.com"] }
        let(:tool_configuration) { described_class.create_tool_config_and_key!(account, params, redirect_uris) }

        it "sets the redirect_uris on the DeveloperKey" do
          expect(tool_configuration.developer_key.redirect_uris).to eq redirect_uris
        end

        it "sets the redirect_uris" do
          expect(tool_configuration[:redirect_uris]).to eq redirect_uris
        end
      end

      it "correctly sets custom_fields" do
        expect(tool_configuration.custom_fields).to eq settings["custom_fields"]
      end

      it "correctly sets privacy_level" do
        expect(tool_configuration[:privacy_level]).to eq params[:privacy_level]
      end

      it "sets redirect_uris column" do
        expect(tool_configuration[:redirect_uris]).to eq [settings["target_link_uri"]]
      end

      %i[title
         description
         target_link_uri
         oidc_initiation_url
         public_jwk
         public_jwk_url
         scopes].each do |field|
        it "sets #{field} column" do
          expect(tool_configuration[field]).to eq settings[field.to_s]
        end
      end

      %i[domain tool_id].each do |field|
        it "sets #{field} column from extensions" do
          expect(tool_configuration[field]).to eq settings.dig("extensions", 0, field.to_s)
        end
      end

      context "when the account is site admin" do
        let_once(:account) { Account.site_admin }

        it "does not set the account on the key" do
          config = described_class.create_tool_config_and_key! account, params
          expect(config.developer_key.account).to be_nil
        end
      end

      context "when tool_config creation fails" do
        let(:settings) { { tool: "foo" } }

        it "does not create dev key" do
          expect(DeveloperKey.where(account:).count).to eq 0
          expect { described_class.create_tool_config_and_key! account, params }.to raise_error ActiveRecord::RecordInvalid
          expect(DeveloperKey.where(account:).count).to eq 0
        end
      end

      context "when settings_url is present" do
        let(:params) do
          {
            settings_url: url
          }
        end
        let(:url) { "https://www.mytool.com/config/json" }
        let(:stubbed_response) do
          double(
            :body => settings.to_json,
            "[]" => "application/json;",
            :is_a? => true
          )
        end

        before do
          allow(CanvasHttp).to receive(:get).and_return(stubbed_response)
        end

        it "fetches JSON from the URL" do
          expect(tool_configuration.settings["target_link_uri"]).to eq settings["target_link_uri"]
        end

        it "adds scopes to dev key" do
          expect(tool_configuration.developer_key.scopes).to eq(settings["scopes"])
        end

        it "set `target_link_uri` to developer_key.redirect_uris" do
          expect(tool_configuration.developer_key.redirect_uris.size).to eq 1
          expect(tool_configuration.developer_key.redirect_uris.first).to eq settings["target_link_uri"]
        end

        context "when a timeout occurs" do
          before { allow(CanvasHttp).to receive(:get).and_raise(Timeout::Error) }

          it "raises exception if timeout occurs" do
            expect { tool_configuration }.to raise_error(/Could not retrieve settings, the server response timed out./)
          end
        end

        context "when the response is not a success" do
          let(:stubbed_response) { double }

          before do
            allow(stubbed_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return false
            allow(stubbed_response).to receive("[]").and_return("application/json")
            allow(CanvasHttp).to receive(:get).and_return(stubbed_response)
          end

          context 'when the response is "not found"' do
            before do
              allow(stubbed_response).to receive_messages(message: "Not found", code: "404")
            end

            it 'adds a "not found error to the model' do
              expect { tool_configuration }.to raise_error(/Not found/)
            end
          end

          context 'when the response is "unauthorized"' do
            before do
              allow(stubbed_response).to receive_messages(message: "Unauthorized", code: "401")
            end

            it 'adds a "unauthorized error to the model' do
              expect { tool_configuration }.to raise_error(/Unauthorized/)
            end
          end

          context 'when the response is "internal server error"' do
            before do
              allow(stubbed_response).to receive_messages(message: "Internal server error", code: "500")
            end

            it 'adds a "internal server error to the model' do
              expect { tool_configuration }.to raise_error(/Internal server error/)
            end
          end

          context "when the response is not JSON" do
            before do
              allow(stubbed_response).to receive("[]").and_return("text/html")
              allow(stubbed_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return true
            end

            it "adds an error to the model" do
              expect { tool_configuration }.to raise_error(%r{Content type must be "application/json"})
            end
          end
        end
      end
    end

    describe "placements" do
      subject { tool_configuration.placements }

      it "returns the appropriate placements" do
        expect(subject).to eq(settings["extensions"].first["settings"]["placements"])
      end
    end

    describe "domain" do
      subject { tool_configuration.domain }

      it { is_expected.to eq(settings["extensions"].first["domain"]) }
    end

    describe "verify_placements" do
      subject { tool_configuration.verify_placements }

      before do
        tool_configuration.save!
      end

      context "when the lti_placement_restrictions feature flag is disabled" do
        before do
          Account.site_admin.disable_feature!(:lti_placement_restrictions)
        end

        it { is_expected.to be_nil }
      end

      %w[submission_type_selection top_navigation].each do |placement|
        context "when the lti_placement_restrictions feature flag is enabled" do
          before do
            Account.site_admin.enable_feature!(:lti_placement_restrictions)
          end

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
    end

    describe "placement_warnings" do
      subject { tool_configuration.placement_warnings }
      context "when the tool does not have resource_selection placement" do
        it "is empty" do
          expect(subject).to eq []
        end
      end

      context "when the tool has resource_selection placement" do
        let(:settings) do
          super().tap do |s|
            s["extensions"].first["settings"]["placements"] << make_placement(
              :resource_selection,
              "LtiResourceLinkRequest"
            )
          end
        end

        it "contains a warning message about deprecation" do
          expect(subject[0]).to include("Warning").and include("deprecated").and include("resource_selection")
        end
      end

      context "when the tool has submission_type_selection placement" do
        let(:settings) do
          super().tap do |s|
            s["extensions"].first["settings"]["placements"] << make_placement(
              :submission_type_selection,
              "LtiResourceLinkRequest"
            )
          end
        end

        it "contains a warning message about approved LTI tools" do
          expect(subject[0]).to include("Warning").and include("submission_type_selection")
        end
      end
    end

    describe "privacy_level" do
      def set_privacy_level
        extensions["privacy_level"] = extension_privacy_level
        tool_configuration.privacy_level = privacy_level
        tool_configuration.settings = settings
        tool_configuration.save!
      end

      subject { tool_configuration[:privacy_level] }

      let(:extension_privacy_level) { "name_only" }
      let(:privacy_level) { raise "set in examples" }
      let(:extensions) { settings["extensions"].first }

      context "when nil" do
        let(:privacy_level) { nil }

        it "is set to the value from canvas_extensions" do
          set_privacy_level
          expect(subject).to eq extension_privacy_level
        end
      end

      context "when already defined" do
        context "when the same as the value from canvas_extensions" do
          before { tool_configuration.privacy_level = extension_privacy_level }

          let(:privacy_level) { extension_privacy_level }

          it "is not reset" do
            set_privacy_level
            expect { subject }.not_to change { tool_configuration[:privacy_level] }
          end
        end

        context "when different from the value in canvas_extensions" do
          let(:privacy_level) { "anonymous" }

          it "is updated to match" do
            set_privacy_level
            expect(subject).to eq extension_privacy_level
          end
        end
      end
    end

    describe "#configuration_changed?" do
      subject { tool_configuration.send :configuration_changed? }

      it { is_expected.to be false }

      context "when settings have changed" do
        before do
          tool_configuration.settings["title"] = "new title"
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

    describe "#deployment_configuration" do
      subject { tool_configuration.developer_key.lti_registration.deployment_configuration }

      context "with settings hash" do
        let(:tool_configuration) { untransformed_tool_configuration }

        it "includes fields from root settings" do
          expect(subject["title"]).to eq settings["title"]
        end

        it "includes canvas extension" do
          expect(subject["domain"]).to eq settings.dig("extensions", 0, "domain")
        end

        it "includes default tool settings" do
          expect(subject[:lti_version]).to eq "1.3"
        end

        context "when model is transformed" do
          let(:old_configuration) { developer_key.lti_registration.deployment_configuration }

          before do
            tool_configuration.settings["oidc_initiation_urls"] = { "us-east-1" => "http://example.com" }
            old_configuration
            tool_configuration.transform!
          end

          it "is functionally equivalent to new version" do
            expect(subject).to eq old_configuration.except("extensions", "platform").deep_stringify_keys.compact
          end
        end
      end

      context "with columns filled" do
        it "does not include redirect_uris" do
          expect(subject.keys).not_to include("redirect_uris")
        end

        it "includes fields from columns" do
          expect(subject["title"]).to eq tool_configuration.title
        end

        it "includes fields from launch_settings" do
          expect(subject.dig("settings", "text")).to eq tool_configuration.launch_settings["text"]
        end

        it "includes default tool settings" do
          expect(subject[:lti_version]).to eq "1.3"
        end
      end
    end

    describe "#transform_settings" do
      subject { tool_configuration.transform_settings }

      let(:tool_configuration) { untransformed_tool_configuration }
      let(:scopes) { ["https://purl.imsglobal.org/spec/lti-ags/scope/lineitem"] }

      it "clears out settings field" do
        subject
        expect(tool_configuration[:settings]).to be_blank
      end

      it "sets target_link_uri" do
        subject
        expect(tool_configuration.target_link_uri).not_to be_blank
        expect(tool_configuration.target_link_uri).to eq settings["target_link_uri"]
      end

      it "sets domain" do
        subject
        expect(tool_configuration.domain).not_to be_blank
        expect(tool_configuration.domain).to eq settings.dig("extensions", 0, "domain")
      end

      it "sets title" do
        subject
        expect(tool_configuration.title).not_to be_blank
        expect(tool_configuration.title).to eq settings["title"]
      end

      it "sets privacy_level" do
        subject
        expect(tool_configuration.privacy_level).not_to be_blank
        expect(tool_configuration.privacy_level).to eq settings.dig("extensions", 0, "privacy_level")
      end

      it "sets tool_id" do
        subject
        expect(tool_configuration.tool_id).not_to be_blank
        expect(tool_configuration.tool_id).to eq settings.dig("extensions", 0, "tool_id")
      end

      it "sets description" do
        subject
        expect(tool_configuration.description).not_to be_blank
        expect(tool_configuration.description).to eq settings["description"]
      end

      it "set oidc_initiation_url" do
        subject
        expect(tool_configuration.oidc_initiation_url).not_to be_blank
        expect(tool_configuration.oidc_initiation_url).to eq settings["oidc_initiation_url"]
      end

      it "sets oidc_initiation_urls" do
        oidc_initiation_urls = { "us-east-1" => "http://example.com" }
        tool_configuration.settings[:oidc_initiation_urls] = oidc_initiation_urls

        subject
        expect(tool_configuration.oidc_initiation_urls).not_to be_blank
        expect(tool_configuration.oidc_initiation_urls).to eq oidc_initiation_urls
      end

      it "sets custom_fields" do
        subject
        expect(tool_configuration.custom_fields).not_to be_blank
        expect(tool_configuration.custom_fields).to eq settings["custom_fields"]
      end

      it "sets scopes" do
        subject
        expect(tool_configuration.scopes).not_to be_blank
        expect(tool_configuration.scopes).to eq scopes
      end

      it "sets public_jwk" do
        subject
        expect(tool_configuration.public_jwk).not_to be_blank
        expect(tool_configuration.public_jwk).to eq settings["public_jwk"]
      end

      it "sets public_jwk_url" do
        public_jwk_url = "https://example.com"
        tool_configuration.settings[:public_jwk_url] = public_jwk_url

        subject
        expect(tool_configuration.public_jwk_url).not_to be_blank
        expect(tool_configuration.public_jwk_url).to eq public_jwk_url
      end

      it "sets launch_settings" do
        launch_settings = settings.dig("extensions", 0, "settings").except("placements")

        subject
        expect(tool_configuration.launch_settings).not_to be_blank
        expect(tool_configuration.launch_settings).to eq launch_settings
      end

      it "sets placements" do
        subject
        expect(tool_configuration.placements).not_to be_blank
        expect(tool_configuration.placements).to eq settings.dig("extensions", 0, "settings", "placements")
      end
    end

    describe "#transform!" do
      subject { tool_configuration.transform! }

      let(:tool_configuration) { untransformed_tool_configuration }

      before do
        allow(tool_configuration).to receive(:transform_settings).and_return(true)
      end

      it "transforms the model" do
        subject
        expect(tool_configuration).to have_received(:transform_settings)
      end

      it "sets redirect_uris" do
        subject
        expect(tool_configuration.redirect_uris).to eq developer_key.redirect_uris
      end

      context "with invalid model" do
        before do
          tool_configuration.settings["public_jwk"] = []
        end

        it "does not raise an error" do
          expect { subject }.not_to raise_error
        end

        it "transforms the model" do
          subject
          expect(tool_configuration).to have_received(:transform_settings)
        end
      end

      context "with already transformed model" do
        before do
          allow(tool_configuration).to receive(:transformed?).and_return(true)
        end

        it "does not transform the model" do
          subject
          expect(tool_configuration).not_to have_received(:transform_settings)
        end
      end
    end

    describe "#untransform!" do
      subject { tool_configuration.untransform! }

      context "with untransformed model" do
        let(:tool_configuration) { untransformed_tool_configuration }

        it "does not change the model" do
          expect { subject }.not_to change { tool_configuration }
        end
      end

      it "reports as untransformed" do
        expect(tool_configuration).to be_transformed
        subject
        expect(tool_configuration).not_to be_transformed
      end

      it "puts data back into settings hash" do
        settings = tool_configuration.settings
        subject
        expect(tool_configuration[:settings]).to eq settings
      end

      it "clears out new columns" do
        columns = tool_configuration.internal_lti_configuration.except(:privacy_level).keys
        subject
        columns.each do |column|
          expect(tool_configuration[column]).to be_blank
        end
      end

      it "leaves existing columns" do
        expect { subject }.not_to change { tool_configuration[:privacy_level] }
      end

      context "with invalid model" do
        before do
          tool_configuration.public_jwk = []
        end

        it "does not raise an error" do
          expect { subject }.not_to raise_error
        end

        it "puts data back into settings hash" do
          settings = tool_configuration.settings
          subject
          expect(tool_configuration[:settings]).to eq settings
        end
      end
    end

    describe "transforming" do
      let(:tool_configuration) { untransformed_tool_configuration }

      it "remains equivalent after multiple transforms" do
        settings = tool_configuration.settings.merge("public_jwk_url" => nil)
        tool_configuration.transform!
        new_settings = tool_configuration.settings
        expect(new_settings).to eq settings
        tool_configuration.untransform!
        expect(tool_configuration.settings).to eq new_settings
        expect(tool_configuration.settings).to eq settings
        tool_configuration.transform!
        expect(tool_configuration.settings).to eq new_settings
        expect(tool_configuration.settings).to eq settings
      end
    end

    describe "#transform_updated_settings" do
      subject { tool_configuration.transform_updated_settings }

      let(:tool_configuration) { untransformed_tool_configuration }

      before do
        tool_configuration.transform_settings
      end

      context "when transformed model has settings changes" do
        before do
          tool_configuration.settings = { title: "new title" }
        end

        it "updates columns" do
          expect { subject }.to change { tool_configuration.title }.to("new title")
        end
      end

      context "when transformed model has no settings changes" do
        it "does not update columns" do
          expect { subject }.not_to change { tool_configuration.title }
        end
      end

      context "when model is not transformed" do
        before do
          tool_configuration.settings = { title: "new title" }
          allow(tool_configuration).to receive(:transformed?).and_return(false)
        end

        it "does not update columns" do
          expect { subject }.not_to change { tool_configuration.title }
        end
      end
    end

    describe "#transformed?" do
      subject { tool_configuration.transformed? }

      let(:tool_configuration) { untransformed_tool_configuration }

      it { is_expected.to be false }

      context "when a required column is present" do
        before do
          tool_configuration.target_link_uri = "http://example.com"
        end

        it { is_expected.to be true }
      end
    end

    describe "#settings" do
      subject { tool_configuration.settings }

      let(:tool_configuration) { untransformed_tool_configuration }

      context "when not transformed" do
        it "returns the settings field" do
          expect(subject).to eq tool_configuration[:settings]
        end
      end

      context "when transformed" do
        let(:old_settings) { tool_configuration[:settings] }

        before do
          tool_configuration.settings["oidc_initiation_urls"] = { "us-east-1" => "http://example.com" }
          tool_configuration.settings["public_jwk_url"] = "https://example.com"
          old_settings
          tool_configuration.transform_settings
        end

        it "transforms columns to LtiConfiguration" do
          expect(subject).to eq old_settings
        end
      end
    end

    describe "#set_redirect_uris" do
      subject { tool_configuration.send :set_redirect_uris }

      let(:tool_configuration) { untransformed_tool_configuration }

      context "when not transformed" do
        it "does not set redirect_uris" do
          subject
          expect(tool_configuration.redirect_uris).to be_blank
        end
      end

      context "when transformed" do
        before do
          tool_configuration.transform_settings
        end

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
end
