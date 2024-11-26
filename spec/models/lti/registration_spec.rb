# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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
require_relative "../../lti_1_3_spec_helper"

RSpec.describe Lti::Registration do
  let(:user) { user_model }
  let(:account) { Account.create! }

  describe "validations" do
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_length_of(:admin_nickname).is_at_most(255) }
    it { is_expected.to validate_length_of(:vendor).is_at_most(255) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to have_one(:ims_registration).class_name("Lti::IMS::Registration").with_foreign_key(:lti_registration_id) }
    it { is_expected.to have_one(:developer_key).class_name("DeveloperKey").inverse_of(:lti_registration).with_foreign_key(:lti_registration_id) }
    it { is_expected.to belong_to(:created_by).class_name("User").optional(true) }
    it { is_expected.to belong_to(:updated_by).class_name("User").optional(true) }
    it { is_expected.to have_many(:lti_registration_account_bindings).class_name("Lti::RegistrationAccountBinding") }
  end

  describe "#lti_version" do
    subject { registration.lti_version }

    let(:registration) { lti_registration_model }

    it "returns 1.3" do
      expect(subject).to eq(Lti::V1P3)
    end
  end

  describe "#dynamic_registration?" do
    subject { registration.dynamic_registration? }

    let(:registration) { lti_registration_model }

    context "when ims_registration is present" do
      let(:ims_registration) { lti_ims_registration_model(lti_registration: registration) }

      before do
        ims_registration # instantiate before test runs
      end

      it { is_expected.to be_truthy }
    end

    context "when ims_registration is not present" do
      it { is_expected.to be_falsey }
    end
  end

  describe "#configuration" do
    subject { registration.internal_lti_configuration(context: account) }

    let(:registration) { lti_registration_model(account:) }

    context "when ims_registration is present" do
      let(:ims_registration) { lti_ims_registration_model(lti_registration: registration) }

      before do
        ims_registration # instantiate before test runs
      end

      it "returns the internal_lti_configuration" do
        expect(subject).to eq(ims_registration.internal_lti_configuration)
      end

      context "when the ims_registration has an overlay on itself" do
        let(:icon_url) { "https://example.com/icon.png" }

        before do
          ims_registration.lti_tool_configuration["messages"][0]["placements"] << "course_navigation"
          ims_registration.registration_overlay = {
            "privacy_level" => "email_only",
            "disabledScopes" => [TokenScopes::LTI_AGS_RESULT_READ_ONLY_SCOPE],
            "disabledPlacements" => ["course_navigation"],
            "placements" => [
              {
                "type" => "course_navigation",
                "default" => "disabled",
              },
              {
                "type" => "global_navigation",
                "iconUrl" => icon_url,
              }
            ]
          }
          ims_registration.save!
        end

        it "returns the configuration with the overlay applied" do
          config = subject
          expect(config["privacy_level"]).to eq("email_only")
          expect(config["scopes"]).not_to include(TokenScopes::LTI_AGS_RESULT_READ_ONLY_SCOPE)
          expect(config["placements"].find { |p| p["placement"] == "course_navigation" }).to include("default" => "disabled", "enabled" => false)
        end

        it "only overlays allowed properties for Dyn Reg" do
          overlay = ims_registration.registration_overlay
          overlay["custom_fields"] = { "foo" => "bar" }
          # Avoid validation callbacks to simulate invalid data, like might
          # be in production.
          ims_registration.update_column(:registration_overlay, overlay)

          expect(subject["custom_fields"]).not_to eq({ "foo" => "bar" })
        end
      end

      context "when an Lti::Overlay is present" do
        let(:data) do
          {
            scopes: [TokenScopes::LTI_AGS_LINE_ITEM_SCOPE],
            title: "A Better Title",
            privacy_level: "anonymous",
            disabled_scopes: [TokenScopes::LTI_AGS_RESULT_READ_ONLY_SCOPE],
            placements: {
              global_navigation: {
                icon_url: "https://example.com/icon.png",
                text: "A Better Title",
                message_type: "LtiDeepLinkingRequest"
              }
            }

          }
        end
        let(:overlay) do
          Lti::Overlay.create!(account:,
                               registration: ims_registration.lti_registration,
                               updated_by: user,
                               data:)
        end

        it "returns the configuration with the overlay applied" do
          overlay
          config = subject

          expect(config["privacy_level"]).to eq("anonymous")
          expect(config["title"]).to eq("A Better Title")
          expect(config["scopes"]).not_to include(TokenScopes::LTI_AGS_RESULT_READ_ONLY_SCOPE)
          global_nav_config = config["placements"].find { |p| p["placement"] == "global_navigation" }

          expect(global_nav_config["icon_url"]).to eq("https://example.com/icon.png")
          expect(global_nav_config["text"]).to eq("A Better Title")
        end
      end
    end

    context "when tool_configuration is present" do
      let!(:tool_configuration) do
        dk = dev_key_model_1_3
        dk.tool_configuration.update!(lti_registration: registration)
        dk.tool_configuration
      end

      it "returns the manual_configuration" do
        expect(subject).to eq(tool_configuration.internal_lti_configuration.with_indifferent_access)
      end

      context "when an Lti::Overlay is present" do
        let(:data) do
          {
            scopes: [TokenScopes::LTI_AGS_LINE_ITEM_SCOPE],
            title: "A Better Title",
            privacy_level: "anonymous",
            placements: {
              global_navigation: {
                target_link_uri: "https://example.com/launch?placement=global_navigation",
                icon_url: "https://example.com/icon.png",
                title: "A Better Title",
                message_type: "LtiDeepLinkingRequest"
              },
              module_index_menu_modal: {
                target_link_uri: "https://example.com/launch?placement=module_index_menu_modal",
                icon_url: "https://example.com/icon.png",
                title: "A Better Title",
                message_type: "LtiDeepLinkingRequest"
              }
            }
          }
        end
        let(:overlay) do
          Lti::Overlay.create!(account:,
                               registration:,
                               updated_by: user,
                               data:)
        end

        it "overlays all fields on top of the configuration" do
          overlay

          expect(subject["privacy_level"]).to eq("anonymous")
          expect(subject["title"]).to eq("A Better Title")
          expect(subject["scopes"]).to eq([TokenScopes::LTI_AGS_LINE_ITEM_SCOPE])
          global_nav_config = subject["placements"].find { |p| p["placement"] == "global_navigation" }
          module_config = subject["placements"].find { |p| p["placement"] == "module_index_menu_modal" }

          expect(global_nav_config).to include("target_link_uri" => "https://example.com/launch?placement=global_navigation",
                                               "icon_url" => "https://example.com/icon.png",
                                               "title" => "A Better Title",
                                               "message_type" => "LtiDeepLinkingRequest")
          expect(module_config).to include("target_link_uri" => "https://example.com/launch?placement=module_index_menu_modal",
                                           "icon_url" => "https://example.com/icon.png",
                                           "title" => "A Better Title",
                                           "message_type" => "LtiDeepLinkingRequest")
        end
      end
    end

    context "when neither ims_registration nor manual_configuration is present" do
      # this will change when and 1.1 registrations are supported
      it "is empty" do
        expect(subject).to eq({})
      end
    end
  end

  describe "#deployment_configuration" do
    subject { registration.deployment_configuration(context: account) }

    shared_examples_for "doesn't remove disabled placements" do
      it "doesn't remove disabled placements from the configuration" do
        expect(subject.dig("settings", "global_navigation")).to be_present
        expect(subject.dig("settings", "global_navigation", "enabled")).to be(false)
      end
    end

    let_once(:registration) { lti_registration_model(account:) }

    context "the registration is associated with a manual registration" do
      include_context "lti_1_3_spec_helper"

      before do
        tool_configuration.update!(lti_registration: registration, placements: [{ placement: "global_navigation", target_link_uri: "https://example.com/launch" }])
      end

      context "the tool_configuration has it's own disabled_placements value" do
        before do
          tool_configuration.update!(disabled_placements: ["global_navigation"])
        end

        it_behaves_like "doesn't remove disabled placements"
      end

      context "an Lti::Overlay exists" do
        let(:overlay) do
          Lti::Overlay.create!(account:, updated_by: user, registration:, data: { "disabled_placements" => ["global_navigation"] })
        end

        before do
          overlay
        end

        it_behaves_like "doesn't remove disabled placements"
      end
    end

    context "the registration is associated with a Dynamic Registration" do
      let(:ims_registration) { lti_ims_registration_model(lti_registration: registration) }

      before(:once) do
        ims_registration.update!(lti_registration: registration)
      end

      context "the Dynamic Registration has it's own list of disabledPlacements" do
        before do
          ims_registration.update!(registration_overlay: { "disabledPlacements" => ["global_navigation"] })
        end

        it_behaves_like "doesn't remove disabled placements"
      end

      context "an Lti::Overlay exists" do
        let(:overlay) do
          Lti::Overlay.create!(registration:, updated_by: user, account:, data: { "disabled_placements" => ["global_navigation"] })
        end

        before do
          overlay
        end

        it_behaves_like "doesn't remove disabled placements"
      end
    end
  end

  describe "#icon_url" do
    subject { registration.icon_url }

    let(:registration) { lti_registration_model }

    context "when ims_registration is present" do
      let!(:ims_registration) { lti_ims_registration_model(lti_registration: registration) }

      it "returns the logo_uri" do
        expect(subject).to eq(ims_registration.logo_uri)
      end
    end

    context "when a tool configuration is present" do
      let!(:tool_configuration) do
        dk = dev_key_model_1_3
        dk.tool_configuration.update!(lti_registration: registration)
        dk.tool_configuration
      end

      it "returns the logo_uri" do
        expect(subject).to eq(tool_configuration.settings["extensions"].first["settings"]["icon_url"])
      end
    end

    context "when neither ims_registration nor manual_configuration is present" do
      it "is nil" do
        expect(subject).to be_nil
      end
    end
  end

  describe "#account_binding_for" do
    subject { registration.account_binding_for(account) }

    let(:registration) { lti_registration_model(account:) }
    let(:account) { account_model }
    let(:account_binding) { lti_registration_account_binding_model(registration:, account:) }

    before do
      account_binding # instantiate before test runs
    end

    context "when account is nil" do
      it "returns the account_binding for the registration's account" do
        expect(subject).to eq(account_binding)
      end
    end

    context "when account is not root account" do
      subject { registration.account_binding_for(subaccount) }

      let(:subaccount) { account_model(parent_account: account) }

      it "returns the binding for the nearest root account" do
        expect(subject).to eq(account_binding)
      end
    end

    context "when account is the registration's account" do
      it "returns the correct account_binding" do
        expect(subject).to eq(account_binding)
      end
    end

    context "when there is no binding for account" do
      subject { registration.account_binding_for(account_model) }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "with site admin registration" do
      specs_require_sharding

      let(:registration) { Shard.default.activate { lti_registration_model(account: Account.site_admin) } }
      let(:site_admin_binding) { Shard.default.activate { lti_registration_account_binding_model(registration:, workflow_state: "on", account: Account.site_admin) } }
      let(:account) { @shard2.activate { account_model } }

      before do
        site_admin_binding # instantiate before test runs
      end

      it "prefers site admin binding" do
        expect(@shard2.activate { subject }).to eq(site_admin_binding)
      end

      context "when site admin binding is allow" do
        before do
          site_admin_binding.update!(workflow_state: "allow")
        end

        it "ignores site admin binding" do
          expect(@shard2.activate { subject }).to be_nil
        end
      end
    end
  end

  describe "#overlay_for" do
    subject { registration.overlay_for(context) }

    let(:registration) { lti_registration_model(account:) }
    let(:user) { user_model }
    let(:account) { account_model }
    let(:other_account) { account_model }
    let(:context) { account }
    let(:unused_overlay) do
      Lti::Overlay.create!(account: other_account,
                           registration: lti_registration_model(account: other_account),
                           updated_by: user,
                           data: {
                             "privacy_level" => "public",
                             "title" => "This should never be seen",
                           })
    end
    let(:overlay) do
      Lti::Overlay.create!(account:,
                           registration:,
                           updated_by: user,
                           data: {
                             "privacy_level" => "public",
                             "title" => "A Better Title",
                           })
    end

    before do
      # Ensure there's some data in the database
      unused_overlay
    end

    it "returns the correct overlay" do
      overlay
      expect(subject).to eq(overlay)
    end

    context "when context is nil" do
      let(:context) { nil }

      it "returns the overlay associated with the registration's account" do
        overlay
        expect(subject).to eq(overlay)
      end
    end

    context "when context is a course" do
      let(:context) { course_model(account:) }

      it "returns the overlay associated with the course's account" do
        overlay
        expect(subject).to eq(overlay)
      end
    end

    context "when context is a sub-account" do
      let(:context) { account_model(parent_account: account) }

      it "returns the overlay associated with the parent account" do
        overlay
        expect(subject).to eq(overlay)
      end
    end

    context "with site admin registration" do
      specs_require_sharding

      let(:registration) { Shard.default.activate { lti_registration_model(account: Account.site_admin) } }
      let(:site_admin_overlay) do
        Shard.default.activate do
          Lti::Overlay.create!(account: Account.site_admin, registration:, updated_by: user, data: { "title" => "Site Admin overlay" })
        end
      end
      let(:account) { @shard2.activate { account_model } }
      let(:overlay) do
        @shard2.activate do
          Lti::Overlay.create!(account:, registration:, updated_by: user, data: { "title" => "Account overlay" })
        end
      end
      let(:context) { account }

      it "uses the site admin overlay" do
        site_admin_overlay
        expect(subject).to eq(site_admin_overlay)
      end

      context "when the account has it's own overlay" do
        it "uses the account's overlay" do
          site_admin_overlay
          overlay
          expect(@shard2.activate { subject }).to eq(overlay)
        end
      end
    end
  end

  describe ".preload_account_bindings" do
    subject { Lti::Registration.preload_account_bindings(registrations, account) }

    let(:account) { account_model }
    let(:registrations) { [] }

    def expect_preloaded_bindings(registrations)
      registrations.each do |registration|
        expect(registration.send(:preloaded_account_binding)).to be_present
      end
    end

    context "when account is nil" do
      let(:account) { nil }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when account is not root account" do
      let(:root_account) { account_model }
      let(:account) { account_model(parent_account: root_account) }

      let(:registrations) { [lti_registration_model(account: root_account, bound: true)] }

      it "preloads bindings for nearest root account" do
        subject
        expect_preloaded_bindings(registrations)
      end
    end

    context "with account-level registrations" do
      let(:registrations) do
        [
          lti_registration_model(account:, bound: true, name: "first"),
          lti_registration_model(account:, bound: true, name: "second")
        ]
      end

      it "preloads account_binding on registrations" do
        subject
        expect_preloaded_bindings(registrations)
      end
    end

    context "with site admin registrations" do
      let(:registrations) do
        [
          lti_registration_model(account:, bound: true, name: "first"),
          lti_registration_model(account: Account.site_admin, bound: true, name: "second")
        ]
      end

      it "preloads bindings from site admin registrations" do
        subject
        expect_preloaded_bindings(registrations)
      end

      context "with sharding" do
        specs_require_sharding

        let(:account_registration) { @shard2.activate { lti_registration_model(account:, bound: true, name: "account") } }
        let(:site_admin_registration) { Shard.default.activate { lti_registration_model(account: Account.site_admin, bound: true, name: "site admin") } }
        let(:registrations) { [account_registration, site_admin_registration] }

        it "preloads bindings from site admin registrations" do
          @shard2.activate { subject }
          expect_preloaded_bindings(registrations)
        end
      end
    end
  end

  describe ".associate_bindings" do
    subject { Lti::Registration.send :associate_bindings, registrations, account_bindings }

    let(:registrations) { [lti_registration_model] }
    let(:account_bindings) { [lti_registration_account_binding_model(registration: registrations.first)] }

    context "when binding has no matching registration" do
      before do
        account_bindings << lti_registration_account_binding_model
      end

      it "does not error" do
        expect { subject }.not_to raise_error
      end

      it "associates bindings with registrations" do
        subject
        expect(registrations.first.send(:preloaded_account_binding)).to eq(account_bindings.first)
      end
    end

    it "associates bindings with registrations" do
      subject
      expect(registrations.first.send(:preloaded_account_binding)).to eq(account_bindings.first)
    end
  end

  describe ".preload_overlays" do
    subject { Lti::Registration.preload_overlays(registrations, account) }

    let(:account) { account_model }
    let(:registrations) { [] }
    let(:overlay) { { title: "Test" } }

    def expect_preloaded_overlays(registrations)
      registrations.each do |registration|
        expect(registration.send(:preloaded_overlay)).to be_present
      end
    end

    context "when account is nil" do
      let(:account) { nil }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when account is not root account" do
      let(:root_account) { account_model }
      let(:account) { account_model(parent_account: root_account) }

      let(:registrations) { [lti_registration_model(account: root_account, overlay:)] }

      it "preloads overlays for nearest root account" do
        subject
        expect_preloaded_overlays(registrations)
      end
    end

    context "with account-level registrations" do
      let(:registrations) do
        [
          lti_registration_model(account:, overlay:, name: "first"),
          lti_registration_model(account:, overlay:, name: "second")
        ]
      end

      it "preloads overlays on registrations" do
        subject
        expect_preloaded_overlays(registrations)
      end
    end

    context "with site admin registrations" do
      let(:registrations) do
        [
          lti_registration_model(account:, overlay:, name: "first"),
          lti_registration_model(account: Account.site_admin, overlay:, name: "second")
        ]
      end

      it "preloads overlays from site admin registrations" do
        subject
        expect_preloaded_overlays(registrations)
      end

      context "with sharding" do
        specs_require_sharding

        let(:account_registration) { @shard2.activate { lti_registration_model(account:, overlay:, name: "account") } }
        let(:site_admin_registration) { Shard.default.activate { lti_registration_model(account: Account.site_admin, overlay:, name: "site admin") } }
        let(:registrations) { [account_registration, site_admin_registration] }

        it "preloads overlays from site admin registrations" do
          @shard2.activate { subject }
          expect_preloaded_overlays(registrations)
        end
      end
    end
  end

  describe ".associate_overlays" do
    subject { Lti::Registration.send :associate_overlays, registrations, overlays }

    let(:registrations) { [lti_registration_model] }
    let(:overlays) { [lti_overlay_model(registration: registrations.first)] }

    context "when overlay has no matching registration" do
      before do
        overlays << lti_overlay_model
      end

      it "does not error" do
        expect { subject }.not_to raise_error
      end

      it "associates overlays with registrations" do
        subject
        expect(registrations.first.send(:preloaded_overlay)).to eq(overlays.first)
      end
    end

    it "associates overlays with registrations" do
      subject
      expect(registrations.first.send(:preloaded_overlay)).to eq(overlays.first)
    end
  end

  describe "#inherited?" do
    subject { registration.inherited_for?(account) }

    let(:registration) { lti_registration_model(account: context) }
    let(:context) { account_model }

    context "when account matches registration account" do
      let(:account) { context }

      it { is_expected.to be false }
    end

    context "when account does not match registration account" do
      let(:account) { account_model }

      it { is_expected.to be true }
    end
  end

  describe "#destroy" do
    subject { registration.destroy }

    let(:registration) { lti_registration_model }

    it "marks the registration as deleted" do
      subject
      expect(registration.reload.workflow_state).to eq("deleted")
    end

    context "with an ims_registration" do
      let(:ims_registration) { lti_ims_registration_model(lti_registration: registration) }

      before do
        ims_registration # instantiate before test runs
      end

      it "marks the registration as deleted" do
        subject
        expect(registration.reload.workflow_state).to eq("deleted")
      end

      it "marks the associated ims_registration as deleted" do
        subject
        expect(ims_registration.reload.workflow_state).to eq("deleted")
      end
    end

    context "with an account binding" do
      let(:account_binding) { lti_registration_account_binding_model(registration:) }

      before do
        account_binding # instantiate before test runs
      end

      it "marks the associated account_binding as deleted" do
        subject
        expect(account_binding.reload.workflow_state).to eq("deleted")
      end

      it "marks the registration as deleted" do
        subject
        expect(registration.reload.workflow_state).to eq("deleted")
      end

      it "keeps the association" do
        subject
        expect(registration.reload.lti_registration_account_bindings).to include(account_binding)
      end
    end

    context "with a developer key" do
      let(:developer_key) { developer_key_model(lti_registration: registration, account: registration.account) }

      before do
        developer_key # instantiate before test runs
      end

      it "marks the associated developer_key as deleted" do
        subject
        expect(developer_key.reload.workflow_state).to eq("deleted")
      end

      it "marks the registration as deleted" do
        subject
        expect(registration.reload.workflow_state).to eq("deleted")
      end
    end
  end

  describe "#undestroy" do
    subject { registration.undestroy }

    let(:registration) { lti_registration_model }

    before do
      registration.destroy
    end

    it "marks the registration as active" do
      subject
      expect(registration.reload.workflow_state).to eq("active")
    end

    context "with an ims_registration" do
      let(:ims_registration) { lti_ims_registration_model(lti_registration: registration) }

      before do
        ims_registration.destroy
      end

      it "marks the registration as active" do
        subject
        expect(registration.reload.workflow_state).to eq("active")
      end

      it "marks the associated ims_registration as active" do
        subject
        expect(ims_registration.reload.workflow_state).to eq("active")
      end
    end

    context "with an account binding" do
      let(:account_binding) { lti_registration_account_binding_model(registration:) }

      before do
        account_binding.destroy
        registration.reload
      end

      it "marks the associated account_binding as off" do
        subject
        expect(account_binding.reload.workflow_state).to eq("off")
      end

      it "marks the registration as active" do
        subject
        expect(registration.reload.workflow_state).to eq("active")
      end
    end

    context "with a developer key" do
      let(:developer_key) { developer_key_model(lti_registration: registration, account: registration.account) }

      before do
        developer_key.destroy
      end

      it "marks the associated developer_key as active" do
        subject
        expect(developer_key.reload.workflow_state).to eq("active")
      end

      it "marks the registration as active" do
        subject
        expect(registration.reload.workflow_state).to eq("active")
      end
    end
  end

  describe "after_update" do
    let(:developer_key) do
      DeveloperKey.create!(
        name: "test devkey",
        email: "test@test.com",
        redirect_uri: "http://test.com",
        account_id: account.id,
        skip_lti_sync: false
      )
    end
    let(:lti_registration) do
      Lti::Registration.create!(
        developer_key:,
        name: "test registration",
        admin_nickname: "test reg",
        vendor: "test vendor",
        account_id: account.id,
        created_by: user,
        updated_by: user
      )
    end

    it "updates the developer key after updating lti_registration" do
      lti_registration.update!(admin_nickname: "new test name")
      expect(lti_registration.developer_key.name).to eq("new test name")
    end

    it "does not update the developer key if skip_lti_sync is true" do
      expect(Lti::Registration.where(developer_key:).first).to be_nil
    end
  end
end
