# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

describe Lti::ToolConfigurationCleaner do
  include_context "lti_1_3_tool_configuration_spec_helper"

  let_once(:developer_key) do
    DeveloperKey.create!(is_lti_key: true,
                         public_jwk_url: "https://example.com",
                         redirect_uris: ["https://example.com"],
                         account: root_account,
                         lti_registration: lti_registration_model(account: root_account))
  end
  let_once(:lti_registration) { developer_key.lti_registration }
  let_once(:root_account) { account_model }

  let(:tool_configuration) do
    Lti::ToolConfiguration.new(
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

  describe ".before_validation" do
    subject { tool_configuration.valid? }

    context "dimension fields" do
      it "converts stringified numbers to numbers in launch_settings" do
        tool_configuration.launch_settings.tap do |ls|
          ls["selection_height"] = "800"
          ls["selection_width"] = "600"
          ls["launch_height"] = "400"
          ls["launch_width"] = "500"
        end
        expect(subject).to be(true)
        expect(tool_configuration.launch_settings["selection_height"]).to eq 800
        expect(tool_configuration.launch_settings["selection_width"]).to eq 600
        expect(tool_configuration.launch_settings["launch_height"]).to eq 400
        expect(tool_configuration.launch_settings["launch_width"]).to eq 500
      end

      it "doesn't change non-numeric strings in launch_settings" do
        tool_configuration.launch_settings.tap do |ls|
          ls["selection_height"] = "invalid"
          ls["selection_width"] = "not a number"
          ls["launch_height"] = "nope"
          ls["launch_width"] = "wrong"
        end
        expect(subject).to be(true)
        expect(tool_configuration.launch_settings["selection_height"]).to eq "invalid"
        expect(tool_configuration.launch_settings["selection_width"]).to eq "not a number"
        expect(tool_configuration.launch_settings["launch_height"]).to eq "nope"
        expect(tool_configuration.launch_settings["launch_width"]).to eq "wrong"
      end

      it "converts stringified numbers to numbers in placements" do
        tool_configuration.placements.tap do |p|
          p.first["selection_height"] = "1000"
          p.first["launch_width"] = "750"
        end
        expect(subject).to be(true)
        expect(tool_configuration.placements.first["selection_height"]).to eq 1000
        expect(tool_configuration.placements.first["launch_width"]).to eq 750
      end

      it "doesn't change non-numeric strings in placements" do
        tool_configuration.placements.tap do |p|
          p.first["selection_height"] = "abc"
          p.first["launch_width"] = "def"
        end
        expect(subject).to be(true)
        expect(tool_configuration.placements.first["selection_height"]).to eq "abc"
        expect(tool_configuration.placements.first["launch_width"]).to eq "def"
      end
    end

    context "custom_fields" do
      it "stringifies number values at the top-level" do
        tool_configuration.custom_fields = { "number" => 123 }
        expect(subject).to be(true)
        expect(tool_configuration.custom_fields["number"]).to eql("123")
      end

      it "stringifies boolean values at the top-level" do
        tool_configuration.custom_fields = { "boolean" => true }
        expect(subject).to be(true)
        expect(tool_configuration.custom_fields["boolean"]).to eql("true")
      end

      it "doesn't stringify null" do
        tool_configuration.custom_fields = { "null" => nil }
        # Legacy behavior, will be false when the schema is tightened for reals.
        expect(subject).to be(true)
        expect(tool_configuration.custom_fields["null"]).to be_nil
      end

      it "doesn't change strings" do
        tool_configuration.custom_fields = { "string" => "$value" }
        expect(subject).to be(true)
        expect(tool_configuration.custom_fields["string"]).to eql("$value")
      end

      it "stringifies numbers and booleans in placements" do
        tool_configuration.placements.tap do |p|
          p.first["custom_fields"] = { foo: 4, bar: true }
        end
        expect(subject).to be(true)
        expect(tool_configuration.placements.first["custom_fields"]).to eql({ foo: "4", bar: "true" })
      end
    end

    context "privacy level" do
      it "converts unknown values to anonymous" do
        tool_configuration.privacy_level = "PRIVATE"
        expect(subject).to be(true)
        expect(tool_configuration.privacy_level).to eql(LtiOutbound::LTITool::PRIVACY_LEVEL_ANONYMOUS.to_s)
      end

      it "doesn't change valid privacy levels" do
        tool_configuration.privacy_level = privacy_level
        expect(subject).to be(true)
        expect(tool_configuration.privacy_level).to eql(privacy_level)
      end
    end

    context "public_jwk" do
      it "coerces a blank object to nil" do
        tool_configuration.public_jwk = {}
        subject
        expect(tool_configuration.public_jwk).to be_nil
      end

      it "coerces an empty array to nil" do
        tool_configuration.public_jwk = []
        subject
        expect(tool_configuration.public_jwk).to be_nil
      end

      it "doesn't coerce a valid JWK to nil" do
        tool_configuration.public_jwk = Factories::LTI_TOOL_CONFIGURATION_BASE_ATTRS[:public_jwk]
        expect(subject).to be(true)
        expect(tool_configuration.public_jwk).to eq(Factories::LTI_TOOL_CONFIGURATION_BASE_ATTRS[:public_jwk].with_indifferent_access)
      end

      it "doesn't coerce a populated array to nil" do
        tool_configuration.public_jwk = [1, 2, 3, 4]
        expect(subject).to be(false)
        expect(tool_configuration.public_jwk).to eq([1, 2, 3, 4])
      end
    end

    context "placement enablement" do
      it "converts stringified booleans to regular booleans" do
        tool_configuration.placements.tap do |p|
          p.first["enabled"] = "true"
          p.last["enabled"] = "false"
        end
        expect(subject).to be(true)
        expect(tool_configuration.placements.first["enabled"]).to be true
        expect(tool_configuration.placements.last["enabled"]).to be false
      end

      it "doesn't modify regular booleans" do
        tool_configuration.placements.tap do |p|
          p.first["enabled"] = true
          p.last["enabled"] = false
        end
        expect(subject).to be(true)
        expect(tool_configuration.placements.first["enabled"]).to be true
        expect(tool_configuration.placements.last["enabled"]).to be false
      end

      it "coerces weird strings" do
        tool_configuration.placements.tap do |p|
          p.first["enabled"] = "whatintheworldisthis"
          p.last["enabled"] = "wellthisissureodd"
        end

        expect { subject }.to change { [tool_configuration.placements.first["enabled"], tool_configuration.placements.last["enabled"]] }.to [false, false]
      end

      it "converts various boolean-like values using Canvas::Plugin.value_to_boolean" do
        tool_configuration.placements.tap do |p|
          p.first["enabled"] = "yes"
          p.last["enabled"] = "0"
        end
        subject
        expect(tool_configuration.placements.first["enabled"]).to be true
        expect(tool_configuration.placements.last["enabled"]).to be false
      end
    end

    context "default field" do
      it "leaves correct values as-is in launch_settings" do
        tool_configuration.launch_settings["default"] = "enabled"
        expect(subject).to be(true)
        expect(tool_configuration.launch_settings["default"]).to eq "enabled"
      end

      it "doesn't mess with correct values" do
        tool_configuration.placements.tap do |p|
          p.find { it["placement"] == "account_navigation" }["default"] = "disabled"
        end

        expect(subject).to be(true)
        expect(tool_configuration.placements.find { |p| p["placement"] == "account_navigation" }["default"]).to eq "disabled"
        tool_configuration.placements.tap do |p|
          p.find { it["placement"] == "account_navigation" }["default"] = "enabled"
        end
        expect(subject).to be(true)
        expect(tool_configuration.placements.find { |p| p["placement"] == "account_navigation" }["default"]).to eq "enabled"
      end

      it "converts 'true' to 'enabled'" do
        tool_configuration.placements.each do |placement|
          placement["default"] = "true" if placement["placement"] == "account_navigation"
        end
        expect(subject).to be(true)
        account_nav = tool_configuration.placements.find { |p| p["placement"] == "account_navigation" }
        expect(account_nav).not_to be_nil
        expect(account_nav["default"]).to eq "enabled"
      end

      it "converts 'false' to 'enabled'" do
        tool_configuration.placements.each do |placement|
          placement["default"] = "false" if placement["placement"] == "course_navigation"
        end
        expect(subject).to be(true)
        course_nav = tool_configuration.placements.find { |p| p["placement"] == "course_navigation" }
        expect(course_nav).not_to be_nil
        # "false" == "disabled" is false, so "default" => "enabled" is expected
        expect(course_nav["default"]).to eq "enabled"
      end
    end

    context "use_tray" do
      it "coerces 'true' to true" do
        tool_configuration.placements << {
          "placement" => "editor_button",
          "use_tray" => "true"
        }
        expect(subject).to be(true)
        editor_button = tool_configuration.placements.find { |p| p["placement"] == "editor_button" }
        expect(editor_button).not_to be_nil
        expect(editor_button["use_tray"]).to be(true)
      end

      it "coerces 'false' to false" do
        tool_configuration.placements << {
          "placement" => "editor_button",
          "use_tray" => "false"
        }
        expect(subject).to be(true)
        editor_button = tool_configuration.placements.find { |p| p["placement"] == "editor_button" }
        expect(editor_button).not_to be_nil
        expect(editor_button["use_tray"]).to be(false)
      end

      it "coerces nil to false" do
        tool_configuration.placements << {
          "placement" => "editor_button",
          "use_tray" => nil
        }
        expect(subject).to be(true)
        editor_button = tool_configuration.placements.find { |p| p["placement"] == "editor_button" }
        expect(editor_button).not_to be_nil
        expect(editor_button["use_tray"]).to be(false)
      end

      it "doesn't affect valid values" do
        tool_configuration.placements << {
          "placement" => "editor_button",
          "use_tray" => true
        }
        expect(subject).to be(true)
        editor_button = tool_configuration.placements.find { |p| p["placement"] == "editor_button" }
        expect(editor_button).not_to be_nil
        expect(editor_button["use_tray"]).to be(true)
      end
    end

    context "mixed dirty data" do
      it "cleans all fields and saves successfully" do
        tool_configuration.launch_settings["selection_height"] = "500"
        tool_configuration.placements.tap do |p|
          p.first["enabled"] = "true"
          p.first["selection_width"] = "400"
          p.each do |placement|
            placement["default"] = "yes" if placement["placement"] == "account_navigation"
          end
        end
        expect(subject).to be true
        expect(tool_configuration.launch_settings["selection_height"]).to eq 500
        expect(tool_configuration.placements.first["enabled"]).to be true
        expect(tool_configuration.placements.first["selection_width"]).to eq 400
        account_nav = tool_configuration.placements.find { |p| p["placement"] == "account_navigation" }
        expect(account_nav).to be_present
        expect(account_nav["default"]).to eq "enabled"
      end
    end

    context "infer_default_target_link_uri" do
      it "doesn't change target_link_uri if already present" do
        tool_configuration.target_link_uri = "https://existing.example.com/launch"
        tool_configuration.placements.first["target_link_uri"] = "https://placement.example.com/launch"
        expect(subject).to be(true)
        expect(tool_configuration.target_link_uri).to eq "https://existing.example.com/launch"
      end

      it "infers target_link_uri from first placement with one" do
        tool_configuration.target_link_uri = nil
        tool_configuration.placements = [
          { "placement" => "course_navigation" },
          { "placement" => "account_navigation", "target_link_uri" => "https://inferred.example.com/launch" },
          { "placement" => "assignment_selection", "target_link_uri" => "https://other.example.com/launch" }
        ]
        expect(subject).to be(true)
        expect(tool_configuration.target_link_uri).to eq "https://inferred.example.com/launch"
      end

      it "doesn't change target_link_uri if placements is empty array" do
        tool_configuration.target_link_uri = nil
        tool_configuration.placements = []
        expect(subject).to be(false)
        expect(tool_configuration.target_link_uri).to be_nil
      end

      it "doesn't change target_link_uri if no placements have target_link_uri" do
        tool_configuration.target_link_uri = nil
        tool_configuration.placements = [
          { "placement" => "course_navigation" },
          { "placement" => "account_navigation" }
        ]
        expect(subject).to be(false)
        expect(tool_configuration.target_link_uri).to be_nil
      end

      it "handles empty string target_link_uri in placements" do
        tool_configuration.target_link_uri = nil
        tool_configuration.placements = [
          { "placement" => "course_navigation", "target_link_uri" => "" },
          { "placement" => "account_navigation", "target_link_uri" => "https://valid.example.com/launch" }
        ]
        expect(subject).to be(true)
        expect(tool_configuration.target_link_uri).to eq "https://valid.example.com/launch"
      end
    end

    context "window target" do
      it "keeps '_blank' value" do
        tool_configuration.placements.first["windowTarget"] = "_blank"
        expect(subject).to be(true)
        expect(tool_configuration.placements.first["windowTarget"]).to eq "_blank"
      end

      ["", "_self", "_parent", "_top"].each do |v|
        it "removes windowTarget if set to #{v}" do
          tool_configuration.placements.first["windowTarget"] = v
          expect(subject).to be(true)
          expect(tool_configuration.placements.first).not_to have_key("windowTarget")
        end
      end

      it "handles multiple placements with windowTarget correctly" do
        tool_configuration.placements = [
          { "placement" => "course_navigation", "windowTarget" => "_blank" },
          { "placement" => "account_navigation", "windowTarget" => "_self" },
          { "placement" => "assignment_selection", "windowTarget" => "_parent" }
        ]
        expect(subject).to be(true)
        expect(tool_configuration.placements[0]["windowTarget"]).to eq "_blank"
        expect(tool_configuration.placements[1]).not_to have_key("windowTarget")
        expect(tool_configuration.placements[2]).not_to have_key("windowTarget")
      end

      it "doesn't crash with empty placements array" do
        tool_configuration.placements = []
        expect(subject).to be(true)
      end

      it "doesn't crash when placement doesn't have windowTarget key" do
        tool_configuration.placements.first.delete("windowTarget")
        expect(subject).to be(true)
        expect(tool_configuration.placements.first).not_to have_key("windowTarget")
      end
    end

    context "visibility field" do
      it "converts 'admin' to 'admins'" do
        tool_configuration.placements.first["visibility"] = "admin"
        expect(subject).to be(true)
        expect(tool_configuration.placements.first["visibility"]).to eq "admins"
      end

      it "handles multiple placements with visibility correctly" do
        tool_configuration.placements = [
          { "placement" => "course_navigation", "visibility" => "admin" },
          { "placement" => "account_navigation", "visibility" => "admins" },
          { "placement" => "assignment_selection", "visibility" => "members" }
        ]
        expect(subject).to be(true)
        expect(tool_configuration.placements[0]["visibility"]).to eq "admins"
        expect(tool_configuration.placements[1]["visibility"]).to eq "admins"
        expect(tool_configuration.placements[2]["visibility"]).to eq "members"
      end

      it "doesn't crash with empty placements array" do
        tool_configuration.placements = []
        expect(subject).to be(true)
      end
    end
  end
end
